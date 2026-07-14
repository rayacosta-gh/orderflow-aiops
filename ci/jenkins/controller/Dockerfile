FROM jenkins/jenkins:2.568.1-lts-jdk21

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Baked outside /var/jenkins_home so it isn't shadowed once the home
# directory volume mounts over the image's filesystem at runtime.
COPY jenkins.yaml /usr/share/jenkins/casc_configs/jenkins.yaml
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/casc_configs/jenkins.yaml
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
