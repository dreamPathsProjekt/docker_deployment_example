from prometheus_client import start_http_server, REGISTRY, Metric

import docker
import collections
import time
import time_helpers



client = docker.from_env()


GaugeTuple = collections.namedtuple('GaugeTuple', ['service_name', 'desired_replicas', 'live_replicas'])

class CustomCollector(object):
    def collect(self):
        desired_metric = Metric('desired_replicas', 'Desired Replicas', 'gauge')
        services = client.services.list()
        gauges = build_gauges(services)

        for gau in gauges:
            name = sanitize(gau.service_name)
            desired_metric.add_sample('live_{}'.format(name), labels={}, value=float(gau.live_replicas))
            desired_metric.add_sample('desired_{}'.format(name), labels={}, value=float(gau.desired_replicas))
            yield desired_metric




def sanitize(gauge_name):
    return str(gauge_name).replace('-','_')

def build_gauges(services):

    gauges = []
    for service in services:
        name = service.name
        live_replicas = get_live_replicas(service)
        desired_replicas = get_desired_replicas(service)
        gt = GaugeTuple(service_name=name, desired_replicas=desired_replicas, live_replicas=live_replicas)
        gauges.append(gt)

    return gauges

def get_desired_replicas(service):
    desired_replicas = 0
    if 'Replicated' in service.attrs['Spec']['Mode'].keys():
        desired_replicas = service.attrs['Spec']['Mode']['Replicated']['Replicas']
    elif 'Global' in service.attrs['Spec']['Mode'].keys():
        desired_replicas = 1

    return desired_replicas

def get_live_replicas(service):
    tasks = service.tasks()
    live_replicas = 0

    if tasks:
        if 'Replicated' in service.attrs['Spec']['Mode'].keys():
            slots = list(int(task['Slot']) if 'Slot' in task.keys() else [0] for task in tasks)
            nr_of_slots = sorted(slots)[-1]
            for slot in range(1, nr_of_slots + 1):
                # print(slot)
                filter_tasks = list(filter(lambda task: task['Slot'] == slot, tasks))
                sorted_tasks = time_helpers.sort_tasks_by_timestamp(filter_tasks)
                try:
                    if sorted_tasks[-1]['Status']['State'] == 'running':
                        live_replicas += 1
                except IndexError:
                    if len(sorted_tasks) == 1 and sorted_tasks[0]['Status']['State'] == 'running':
                        live_replicas += 1
        elif 'Global' in service.attrs['Spec']['Mode'].keys():
            sorted_tasks = time_helpers.sort_tasks_by_timestamp(tasks)
            if sorted_tasks[-1]['Status']['State'] == 'running':
                live_replicas += 1


    return live_replicas



if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(8000)
    REGISTRY.register(CustomCollector())
    # Generate some requests.
    while True:
        REGISTRY.collect()
        time.sleep(2)
