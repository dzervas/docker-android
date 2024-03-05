FROM openjdk:22-jdk-bookworm

LABEL maintainer "Amr Salem"
LABEL maintainer "Dimitris Zervas"

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /
#=============================
# Install Dependenices
#=============================
RUN apt-get update && apt-get install -y \
    curl \
    bash \
    git \
    net-tools \
    novnc \
    supervisor \
    sudo \
    wget \
    unzip \
    bzip2 \
    libdrm-dev \
    libxkbcommon-dev \
    libgbm-dev \
    libasound-dev \
    libnss3 \
    libxcursor1 \
    libpulse-dev \
    libxshmfence-dev \
    xauth \
    xvfb \
    x11vnc \
    fluxbox \
    wmctrl \
    libdbus-c++-bin \
    libdbus-glib-1-2

#==============================
# Android SDK ARGS
#==============================
ARG ARCH="x86_64"
ARG TARGET="google_apis_playstore"
ARG API_LEVEL="34"
ARG BUILD_TOOLS="${API_LEVEL}.0.0"
ARG ANDROID_ARCH=${ANDROID_ARCH_DEFAULT}
ARG ANDROID_API_LEVEL="android-${API_LEVEL}"
ARG ANDROID_APIS="${TARGET};${ARCH}"
ARG EMULATOR_PACKAGE="system-images;${ANDROID_API_LEVEL};${ANDROID_APIS}"
ARG PLATFORM_VERSION="platforms;${ANDROID_API_LEVEL}"
ARG BUILD_TOOL="build-tools;${BUILD_TOOLS}"
ARG ANDROID_CMD="commandlinetools-linux-11076708_latest.zip"
ARG ANDROID_SDK_PACKAGES="${EMULATOR_PACKAGE} ${PLATFORM_VERSION} ${BUILD_TOOL} platform-tools"

#==============================
# Set JAVA_HOME - SDK
#==============================
ENV ANDROID_SDK_ROOT=/opt/android
ENV PATH "$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/${BUILD_TOOLS}"
ENV DOCKER="true"

#============================================
# Install required Android CMD-line tools
#============================================
RUN wget https://dl.google.com/android/repository/${ANDROID_CMD} -P /tmp && \
              unzip -d $ANDROID_SDK_ROOT /tmp/$ANDROID_CMD && \
              mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/tools && cd $ANDROID_SDK_ROOT/cmdline-tools &&  mv NOTICE.txt source.properties bin lib tools/  && \
              cd $ANDROID_SDK_ROOT/cmdline-tools/tools && ls

#============================================
# Install required package using SDK manager
#============================================
RUN yes Y | sdkmanager --licenses
RUN yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES}

#============================================
# Create required emulator
#============================================
ARG EMULATOR_NAME="nexus"
ARG EMULATOR_DEVICE="Nexus 6"
ENV EMULATOR_NAME=$EMULATOR_NAME
ENV DEVICE_NAME=$EMULATOR_DEVICE
RUN echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME}" --device "${EMULATOR_DEVICE}" --package "${EMULATOR_PACKAGE}"

#====================================
# Install latest nodejs, npm & appium
#====================================
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g npm && \
    npm i -g appium --unsafe-perm=true --allow-root && \
    appium driver install uiautomator2 && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -Rf /tmp/* && rm -Rf /var/lib/apt/lists/*


#===================
# Alias
#===================
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html
ENV EMU=./start_emu.sh
ENV EMU_HEADLESS=./start_emu_headless.sh
ENV VNC=./start_vnc.sh
ENV APPIUM=./start_appium.sh


#===================
# Ports
#===================
ENV APPIUM_PORT=4723 \
    APPIUM_PLUGINS="" \
    ENABLE_X=yes \
    RUN_FLUXBOX=yes \
    RUN_NOVNC=yes \
    RUN_APPIUM=no \
    EMULATOR_FLAGS="-no-snapshot -no-audio" \
    ROOT=no \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1024 \
    DISPLAY_HEIGHT=768 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

#=========================
# Copying Scripts to root
#=========================
COPY . /app
RUN chmod +x /app/*.sh

#=======================
# framework entry point
#=======================
EXPOSE 6080/tcp 4723/tcp 5555/tcp
ENTRYPOINT [ "/app/entrypoint.sh" ]
