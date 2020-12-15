FROM maven:3.6.1-jdk-8 as maven_builder
WORKDIR /app
COPY . /app
RUN mvn clean package

FROM tomcat:8.5.43-jdk8
COPY --from=maven_builder /app/target/*.war /usr/local/tomcat/webapps
ADD ./WebContent/Config.properties /usr/local/tomcat/ROOT/Config.properties
