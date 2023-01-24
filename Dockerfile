#Проверь версию!
FROM php:8.1.0-fpm 

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install npm 9.0
RUN apt-get update && apt-get install -y \
    software-properties-common \
    npm \
    && rm -rf /var/lib/apt/lists/*

# RUN chown -R $user:$user /home/$user/.composer

RUN npm install npm@latest -g && \  
    npm install n -g && \
    n latest

# Clear cache # дописать кэш 
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:2.1.8 /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user && \
    chown -R $user:$user /home/$user/.composer
    # chown -R $user:$user /var/www/vendor/composer/
# Set working directory
WORKDIR /var/www

# RUN chown -R $user:$user /var/www/vendor/composer/

USER $user

