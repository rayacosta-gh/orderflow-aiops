FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml ./
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:21-jre-alpine
# Base image tags are a stale snapshot; patch OS packages at build time
# rather than only relying on the next upstream image rebuild.
RUN apk update && apk upgrade --no-cache
RUN adduser -D appuser
USER appuser
COPY --from=build /src/target/notification-service-0.1.0.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
