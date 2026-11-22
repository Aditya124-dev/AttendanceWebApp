# Stage 1: Build the Java web application
FROM maven:3.9.13-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN for attempt in 1 2 3 4 5; do \
      echo "Maven build attempt: $attempt"; \
      mvn -B -DskipTests -Dmaven.wagon.http.retryHandler.count=5 package && break; \
      if [ "$attempt" -eq 5 ]; then exit 1; fi; \
      sleep "$((attempt * 20))"; \
    done

# Stage 2: Run the application on Tomcat
FROM tomcat:10.1.61-jdk21-temurin-jammy

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["sh", "-c", "sed -i \"s/port=\\\"8080\\\"/port=\\\"${PORT:-8080}\\\"/\" \"$CATALINA_HOME/conf/server.xml\" && exec catalina.sh run"]
