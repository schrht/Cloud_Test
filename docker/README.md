# Install Docker-CE

Please follow this article to install docker-ce:  
[Get Docker CE for Fedora | Docker Documentation](https://docs.docker.com/install/linux/docker-ce/fedora/#install-docker-ce)


# Build the Docker image

`$ sudo docker build -t "shichen/cloud_test" ./`

> - This command will create a Docker image named "shichen/cloud_test" based on the `./Dockerfile`;
> - You can change `shichen` to your own or just remove `shichen/` if you feel nothing to do with the [Docker Repository](https://hub.docker.com/).

# Run a Docker container

`$ sudo docker run --name ct1 -it -v ~/mirror/dockerspace/docker_volumes/ct1_data/:/data/:rw shichen/cloud_test /bin/bash`

> - This command will run a container named "ct1" from image "shichen/cloud_test";
> - It will create dirctory `~/mirror/dockerspace/docker_volumes/ct1_data/` on your local FS and mount it to the container at `/data/` with `rw` premission;

Keep this terminal being opened, you will be able to talk with your container and run the tests in this terminal. (If you closed this terminal, you can follow the tips below)

# Setup Cloud_Test in container

Run the following commands on your local system to setup Cloud_Test into your container:

```
cd ~/mirror/dockerspace/docker_volumes/ct1_data/
sudo git clone https://github.com/SCHEN2015/Cloud_Test.git
sudo docker exec ct1 /data/cloud_test_setup.sh
```

Follow the [instruction from Cloud_Test project](https://github.com/SCHEN2015/Cloud_Test#create-aws-configuration-file) to finish configuration.

# Testing with Cloud_Test in container

Just use it as in a real computer. Meanwhile there are some tips for you to play with the Docker container.

Tips:  
1. Put the container to the background: press `Ctrl-P` then `Ctrl-Q`;
2. Put a container back to the foreground: `sudo docker attach <name>`;
3. Leave a container and make it stopped: just execute `exit` command;
4. Start a stopped container: execute `sudo docker start -i <name>`;
5. Open another terminal on a running container: `sudo docker exec -it <name> /bin/bash`;
6. List all the containers on your system: `sudo docker ps -a`;

All the logs will be available in `~/mirror/dockerspace/docker_volumes/ct1_data/avocado/job-results` according to your configuration. The data stored in this directory will never be lost no matter the container is alive or not, even it has been destoryed.

# Enjoy it

Feel free to reach me if you have further questions.

