```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM tomcat:10.1-jdk17-temurin

COPY isrgrootx1.pem /tmp/isrgrootx1.pem

RUN keytool -importcert -noprompt \
    -alias isrgrootx1 \
    -file /tmp/isrgrootx1.pem \
    -keystore "$JAVA_HOME/lib/security/cacerts" \
    -storepass changeit \
    && rm -f /tmp/isrgrootx1.pem

COPY --from=build /app/target/employee-time-management.war /usr/local/tomcat/webapps/employee-time-management.war

EXPOSE 10000

CMD ["sh", "-c", "sed -i 's/port=\"8080\"/port=\"'\"${PORT:-10000}\"'\"/' \"$CATALINA_HOME/conf/server.xml\" && exec \"$CATALINA_HOME/bin/catalina.sh\" run"]
```