import time


def get_time_from_docker_ts(ts_string):
    return time.mktime(get_parsable_ts(ts_string))


def get_parsable_ts(ts_string):
    return time.strptime(
        ts_string.split('T')[0] +
        " " + ts_string.split('T')[1].split('.')[0],
        '%Y-%m-%d %H:%M:%S')

def get_readable_ts(timestruct):
    return time.strftime('%Y-%m-%d %H:%M:%S', timestruct)

def sort_tasks_by_timestamp(tasks):
    return sorted(tasks,
                  key=lambda docker_task:
                  get_time_from_docker_ts(
                      docker_task['Status']['Timestamp']))
