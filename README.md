# Minecraft Server
Easily deploy a Java Minecraft server to an AWS EC2 instance.

#### Specifying the server version:
By default, the deploy will find and install Minecraft's latest release. You can specify an exact version by editing the `SERVER_VERSION` environment variable in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml#L13).

#### Change the server location
By default, the deploy will deploy your server in the `us-east-1` AWS region. You may change the location of your instance by updating the `REGION` environment variable in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml#L10).

Find the available regions [here](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/).

## How to Deploy
### 1. Create an IAM Role
In your AWS Account, create a new IAM Role with the permissions you deem necessary. This must include [Cloudformation](https://aws.amazon.com/cloudformation/) and [EC2](https://aws.amazon.com/ec2/). Refer to GitHub's docs for [Configuring OpenID Connect in AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) for guidance.

### 2. Create an SSH keypair on AWS
See AWS [Create key pairs documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html). \
By default, the GitHub action that creates the stack uses a key-pair with the name `minecraft-server-key-pair`. You must update the value in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml#L11) if you use a different key-pair name.

**Note:** Make sure to keep your private keyfile on your computer if you plan to [connect to the ec2 instance later](#5-connecting-to-the-ec2-instance-after-deploy).


### 3. Add essential secrets to your GitHub repository.

Add the following secrets via **Repository settings** > **Secrets** > **Actions**.

  - `IAM_ROLE_ARN` containing your IAM Role ARN from step 1.
  - `SSH_PRIVATE_KEY` containing the value inside the keyfile generated in step 2.

### 4. Trigger a deploy
Mnually trigger the **deploy** workflow in the **actions** tab on the repository.

### 5. Connecting to the ec2 instance after deploy
You may SSH into the EC2 instance using the KeyPair from step 2. Refer to the EC2 docs for [connecting to an EC2 instance using SSH](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html).

In the event that you no longer have your keyfile (from step 2) on your computer, you can still execute commands on the server by altering the last step of the "Deploy" job in [`./github/workflows/deploy.yml`](.github/workflows/deploy.yml#L40).

## How to make changes to your server
You may add assets in the `assets` directory that will be automatically copied to the EC2 instance.

For example, to add a custom [`server.properties`](https://minecraft.fandom.com/wiki/Server.properties) file, simply add the file to the `assets` folder. The server will automatically restart with your new properties once you push your changes.


---
## GitHub Action workflows

### Deploying (and starting) the server
As mentioned in the steps above, you may trigger the deploy workflow via pushing changes. Alternatively, you may trigger a deploy by running the **Deploy** worklow from within the **Actions** tab.

#### Deleting your server
If you want to delete the Cloudformation stack from AWS entirely, simply run the **Delete** workflow from within the **Actions** tab.