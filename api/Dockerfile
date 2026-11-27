FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn -q dependency:go-offline

COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
RUN useradd -m -u 10001 appuser
WORKDIR /app

COPY --from=build --chown=appuser:appuser /workspace/target/*.jar /app/app.jar
USER appuser

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+UseSerialGC -Xss512k"
EXPOSE 8081

CMD java $JAVA_OPTS -jar /app/app.jar
