FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN groupadd --system splitdebt && useradd --system --gid splitdebt --home-dir /app splitdebt && chown splitdebt:splitdebt /app
COPY --from=build /src/target/api-0.0.1-SNAPSHOT.jar app.jar
USER splitdebt
EXPOSE 8081
ENTRYPOINT ["java","-jar","app.jar"]
