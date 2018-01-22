# Docker Deployment Example Using Stack Deploy & Docker Swarm

## Create Docker Secrets

On Docker Host:

```bash
echo 'xxxxx' | docker secret create lb_admin_user -
echo 'xxxxx' | docker secret create lb_admin_pass -
```

In this example (demo purposes):

- lb_admin_user: admin
- lb_admin_pass: pass!word