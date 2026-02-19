Update the Server

------------------



sudo apt update \&\& sudo apt upgrade -y

sudo apt install unzip curl git -y



Step 2: Install PHP + Extensions



Laravel 12+ requires PHP ≥ 8.1. Let’s install PHP 8.3 (same as your working server):

------------------------------------------------------------------------------------



sudo apt install software-properties-common -y

sudo add-apt-repository ppa:ondrej/php -y

sudo apt update

sudo apt install php8.3 php8.3-cli php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-bcmath unzip -y





Step 3: Install Nginx

-------------------

sudo apt install nginx -y

sudo systemctl enable nginx

sudo systemctl start nginx





Step 4: Install MySQL

-------------------

sudo apt install mysql-server -y

sudo systemctl enable mysql

sudo systemctl start mysql





Secure MySQL:

------------



sudo mysql\_secure\_installation





* Set root password
* 
* Remove anonymous users → Yes
* 
* Disallow root remote login → Yes
* 
* Remove test database → Yes
* 
* Reload privileges → Yes



Step 5: Create Database and User



Login to MySQL:

--------------

mysql -u root -p





Inside MySQL:

-------------

CREATE DATABASE laravel\_db;

CREATE USER 'laravel\_user'@'localhost' IDENTIFIED BY 'StrongPassword@123';

GRANT ALL PRIVILEGES ON laravel\_db.\* TO 'laravel\_user'@'localhost';

FLUSH PRIVILEGES;

EXIT;





clone code

----------

sudo mv /var/www/Analogue-GPS /var/www/dev



set permissions for nginx

==========================

sudo chown -R www-data:www-data /var/www/dev

sudo find /var/www/dev -type d -exec chmod 755 {} \\;

sudo find /var/www/dev -type f -exec chmod 644 {} \\;

sudo chmod -R 775 /var/www/dev/storage /var/www/dev/bootstrap/cache





Copy .env.example:

--------------------



cd /var/www/dev

cp .env.example .env





Edit .env:

----------



nano .env





Update DB info:

------------------



DB\_CONNECTION=mysql

DB\_HOST=127.0.0.1

DB\_PORT=3306

DB\_DATABASE=laravel\_db

DB\_USERNAME=laravel\_user

DB\_PASSWORD=StrongPassword@123





php artisan key:generate



✅ Step 1: Install PHP GD Extension

-----------------------------------



Since you are on PHP 8.3, run:



sudo apt install php8.3-gd -y



✅ Step 2: Restart PHP-FPM

---------------------------

sudo systemctl restart php8.3-fpm



install depencies for php

-------------------------

sudo apt install composer -y

composer install --no-dev --optimize-autoloader



upload data to MySQL

--------------------

mysql -u laravel\_user -p laravel\_db < gps-tracker.sql



Step 10: Configure Nginx

----------------------



Create site config:



sudo nano /etc/nginx/sites-available/dev





update

--------

server {

&nbsp;   listen 80;

&nbsp;   server\_name dev.bmrjewells.com; # your domain or \_ for IP



&nbsp;   root /var/www/dev/public; #careful

&nbsp;   index index.php index.html;



&nbsp;   location / {

&nbsp;       try\_files $uri $uri/ /index.php?$query\_string;

&nbsp;   }



&nbsp;   location ~ \\.php$ {

&nbsp;       include snippets/fastcgi-php.conf;

&nbsp;       fastcgi\_pass unix:/var/run/php/php8.3-fpm.sock;

&nbsp;   }



&nbsp;   location ~ /\\.ht {

&nbsp;       deny all;

&nbsp;   }

}



enable site

-----------

sudo ln -s /etc/nginx/sites-available/dev /etc/nginx/sites-enabled/

sudo rm /etc/nginx/sites-enabled/default

sudo nginx -t

sudo systemctl restart nginx





Step 11: Laravel Storage \& Cache Permissions

--------------------------------------------

sudo chmod -R 775 /var/www/dev/storage /var/www/dev/bootstrap/cache

php artisan config:clear

php artisan cache:clear

php artisan route:clear

php artisan view:clear


Step 1: Install Node.js 20 (Recommended)
Remove old Node (optional but clean)
--------------------------------------
sudo apt remove nodejs -y

Install Node 20 via NodeSource (BEST METHOD)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs -y

Step 2: Verify Version
----------------------
node -v
npm -v


✅ Must show Node ≥ 20.











