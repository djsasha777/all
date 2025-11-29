import asyncio
import os
import yaml
import logging
from kubernetes_asyncio import client, config, watch
import git


# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)
logger = logging.getLogger(__name__)


repo_url = os.getenv('REPO')
branch = os.getenv('BRANCH')
filePath = os.getenv('FILEPATH')
token = os.getenv('TOKEN')
external_label = os.getenv('EXTERNAL')


def get_auth_repo_url(repo_url, token):
    try:
        if repo_url.startswith("https://"):
            return repo_url.replace("https://", f"https://{token}@")
        return repo_url
    except Exception as e:
        logger.error(f"Error in get_auth_repo_url: {e}")
        raise


def clone_or_update_repo(auth_repo_url, branch, repo_path="/tmp/repo"):
    try:
        if not os.path.exists(repo_path):
            logger.info("Cloning repository...")
            repo = git.Repo.clone_from(auth_repo_url, repo_path, branch=branch)
        else:
            repo = git.Repo(repo_path)
            repo.git.checkout(branch)
            logger.info("Pulling latest changes from the repository...")
            repo.remotes.origin.pull()
        return repo
    except Exception as e:
        logger.error(f"Error in clone_or_update_repo: {e}")
        raise


def update_haproxy(repo, subdomain, ingress_ip, has_issuer):
    try:
        values_path = os.path.join(repo.working_tree_dir, filePath)

        with open(values_path, 'r') as f:
            data = yaml.safe_load(f) or {}

        if "haproxySubdomain" not in data or data["haproxySubdomain"] is None:
            data["haproxySubdomain"] = []
        if "acmeSubdomain" not in data or data["acmeSubdomain"] is None:
            data["acmeSubdomain"] = []

        found_haproxy = False
        found_acme = False

        for entry in data["haproxySubdomain"]:
            if entry.get("name") == subdomain:
                entry["ip"] = ingress_ip
                entry["port"] = 443
                entry["proxy"] = False
                found_haproxy = True
                break

        if has_issuer:
            for entry in data["acmeSubdomain"]:
                if entry.get("name") == subdomain:
                    entry["ip"] = ingress_ip
                    entry["port"] = 80
                    found_acme = True
                    break

        if not found_haproxy:
            data["haproxySubdomain"].append({
                "name": subdomain,
                "ip": ingress_ip,
                "port": 443,
                "proxy": False
            })

        if has_issuer and not found_acme:
            data["acmeSubdomain"].append({
                "name": subdomain,
                "ip": ingress_ip,
                "port": 80
            })

        with open(values_path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False)

        repo.git.add(filePath)
        if repo.is_dirty(untracked_files=False):
            repo.index.commit(f"Update haproxySubdomain with subdomain: {subdomain}")
            origin = repo.remote(name='origin')
            origin.push(branch)
            logger.info(f"Git changes pushed for {subdomain}")
        else:
            logger.info(f"No changes detected for subdomain {subdomain}, skipping commit and push")

    except Exception as e:
        logger.error(f"Error in update_haproxy for subdomain {subdomain}: {e}")


def remove_ingress_from_yaml(repo, subdomain):
    try:
        values_path = os.path.join(repo.working_tree_dir, filePath)
        with open(values_path, 'r') as f:
            data = yaml.safe_load(f) or {}

        if "haproxySubdomain" in data and data["haproxySubdomain"]:
            data["haproxySubdomain"] = [entry for entry in data["haproxySubdomain"] if entry.get("name") != subdomain]

        if "acmeSubdomain" in data and data["acmeSubdomain"]:
            data["acmeSubdomain"] = [entry for entry in data["acmeSubdomain"] if entry.get("name") != subdomain]

        with open(values_path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False)

        repo.git.add(filePath)
        if repo.is_dirty(untracked_files=False):
            repo.index.commit(f"Remove ingress {subdomain} from haproxy and acme subdomains")
            origin = repo.remote(name='origin')
            origin.push(branch)
            logger.info(f"Removed ingress {subdomain} and pushed changes")
        else:
            logger.info(f"No changes detected for ingress {subdomain}, skipping commit and push")

    except Exception as e:
        logger.error(f"Error in remove_ingress_from_yaml for subdomain {subdomain}: {e}")


def add_service_to_haproxy(repo, service_name, service_ip):
    try:
        values_path = os.path.join(repo.working_tree_dir, filePath)

        with open(values_path, 'r') as f:
            data = yaml.safe_load(f) or {}

        if "haproxySubdomain" not in data or data["haproxySubdomain"] is None:
            data["haproxySubdomain"] = []

        for entry in data["haproxySubdomain"]:
            if entry.get("name") == service_name:
                entry["ip"] = service_ip
                entry["port"] = 443
                entry["proxy"] = False
                break
        else:
            data["haproxySubdomain"].append({
                "name": service_name,
                "ip": service_ip,
                "port": 443,
                "proxy": False
            })

        with open(values_path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False)

        repo.git.add(filePath)
        if repo.is_dirty(untracked_files=False):
            repo.index.commit(f"Add/update service {service_name} in haproxySubdomain")
            origin = repo.remote(name='origin')
            origin.push(branch)
            logger.info(f"Git changes pushed for service {service_name}")
        else:
            logger.info(f"No changes detected for service {service_name}, skipping commit and push")

    except Exception as e:
        logger.error(f"Error in add_service_to_haproxy for service {service_name}: {e}")


def remove_service_from_haproxy(repo, service_name):
    try:
        values_path = os.path.join(repo.working_tree_dir, filePath)
        with open(values_path, 'r') as f:
            data = yaml.safe_load(f) or {}

        if "haproxySubdomain" in data and data["haproxySubdomain"]:
            data["haproxySubdomain"] = [entry for entry in data["haproxySubdomain"] if entry.get("name") != service_name]

        with open(values_path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False)

        repo.git.add(filePath)
        if repo.is_dirty(untracked_files=False):
            repo.index.commit(f"Remove service {service_name} from haproxySubdomain")
            origin = repo.remote(name='origin')
            origin.push(branch)
            logger.info(f"Removed service {service_name} and pushed changes")
        else:
            logger.info(f"No changes detected for service {service_name}, skipping commit and push")

    except Exception as e:
        logger.error(f"Error in remove_service_from_haproxy for service {service_name}: {e}")

async def watch_ingress(repo, api_client):
    networking_v1 = client.NetworkingV1Api(api_client)
    w = watch.Watch()
    while True:
        try:
            async for event in w.stream(networking_v1.list_ingress_for_all_namespaces, timeout_seconds=60):
                event_type = event['type']
                ingress = event['object']
                annotations = ingress.metadata.annotations or {}

                if annotations.get('kubernetes.io/ingress.class') != 'nginx':
                    continue

                subdomain = annotations.get('subdomain')
                if not subdomain:
                    continue  # пропускаем если аннотация subdomain отсутствует

                if event_type in ['ADDED', 'MODIFIED']:
                    ingress_ip = annotations.get('inControllerIP')
                    has_issuer = annotations.get('cert-manager.io/cluster-issuer') == "letsencrypt-production"
                    logger.info(f"New ingress - Subdomain: {subdomain}, IP: {ingress_ip}, Has issuer: {has_issuer}")
                    update_haproxy(repo, subdomain, ingress_ip, has_issuer)

                elif event_type == 'DELETED':
                    logger.info(f"Ingress deleted - Subdomain: {subdomain}. Removing from YAML...")
                    remove_ingress_from_yaml(repo, subdomain)

        except Exception as e:
            logger.error(f"Watch ingress error: {e}")
            await asyncio.sleep(10)


async def watch_service(repo, api_client):
    core_v1 = client.CoreV1Api(api_client)
    w = watch.Watch()
    while True:
        try:
            async for event in w.stream(core_v1.list_service_for_all_namespaces, timeout_seconds=60):
                event_type = event['type']
                service = event['object']
                labels = service.metadata.labels or {}

                if service.spec.type != "LoadBalancer" or external_label not in labels:
                    continue

                service_name = service.metadata.name

                if event_type in ['ADDED', 'MODIFIED']:
                    service_ip = None
                    if service.status.load_balancer and service.status.load_balancer.ingress:
                        service_ip = service.status.load_balancer.ingress[0].ip if len(service.status.load_balancer.ingress) > 0 else None
                    logger.info(f"New service - Name: {service_name}, IP: {service_ip}, Label found: {external_label}")
                    if service_ip:
                        add_service_to_haproxy(repo, service_name, service_ip)

                elif event_type == 'DELETED':
                    logger.info(f"Service deleted - Name: {service_name}. Removing from YAML...")
                    remove_service_from_haproxy(repo, service_name)

        except Exception as e:
            logger.error(f"Watch service error: {e}")
            await asyncio.sleep(10)


async def main_async():
    logger.info("Starting Kubernetes ingress and service watcher (async)")

    try:
        config.load_incluster_config()
    except Exception as e:
        logger.error(f"Error loading in-cluster config: {e}")
        return

    try:
        auth_repo_url = get_auth_repo_url(repo_url, token)
        repo = clone_or_update_repo(auth_repo_url, branch)
    except Exception as e:
        logger.error(f"Error setting up git repo: {e}")
        return

    async with client.ApiClient() as api_client:
        await asyncio.gather(
            watch_ingress(repo, api_client),
            watch_service(repo, api_client),
        )


if __name__ == "__main__":
    asyncio.run(main_async())
