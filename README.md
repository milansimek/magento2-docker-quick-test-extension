#Magento 2 extension quick test docker image

<hr>

####Apache 2.4 + PHP 5.6 / 7.0 / 7.1 / 7.2 + MySQL + MailDev


##Usage
### Building the image
First clone this repository   
```
git clone git@github.com:milansimek/magento2-extension-quick-test-box.git
```
In project root execute the following command to build a testing image
```
docker build \
--build-arg MAGENTO_VERSION={MAGENTO_VERSION} \
--build-arg PHP_VERSION={PHP_VERSION} \
--build-arg BASE_URL={BASE_URL}:{PORT} \
-t {IMAGE_NAME} .
```
You can replace all the variables inside curly braces {} as you see fit. For example:
```
docker build \
--build-arg MAGENTO_VERSION=2.2.1 \
--build-arg PHP_VERSION=7.1 \
--build-arg BASE_URL=local.dev:8080 \
-t testbox-php7.1-mage-2.2.1 .
```
The example command above creates a test box based on php 7.1 + Magento 2.2.1.    
   
You could change the php version to 5.6 and Magento version to 2.1.10 etc. You can create as many images as you need.

### Using the image
After the image is built you can run your test box as follows:

```
docker run \
-p 8080:80 -p 1080:1080 \
-v /path/to/local/app/code:/var/www/html/app/code \
testbox-php7.1-mage-2.2.1
```

In the above command `/path/to/local/app/code` is the path where your module packages that you want to test reside. Typically this directory will contain one or multiple subdirectories in the format of `CompanyNamespace/PackageName`

Once the image starts up the extensions in the local `app/code` dir will be automatically installed and the compilation process will start + production mode will be enabled.

You can now test your extension at `local.dev:8080` (or your custom base url). 
   
#### Available tools / resources
##### MailDev virtual mailbox
Maildev virtual mailbox is available at `local.dev:1080`   
##### PhpMyAdmin
PhpMyAdmin is available at `local.dev:8080/phpmyadmin`  
user: `admin`  
password: `password123`
##### Magento admin panel
url: `local.dev/admin`   
user: `admin`    
password: `password123`


