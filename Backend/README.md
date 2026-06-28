# Sharecycle Backend

This is the backend for the Sharecycle application, a platform for renting and sharing bicycles.

## Technologies Used

*   Java 17
*   Spring Boot 3
*   Spring Security
*   JPA (Hibernate)
*   MySQL
*   Maven
*   PayPal REST API

## Setup and Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/sharecycle-backend.git
    ```
2.  **Configure the database:**
    *   Open `src/main/resources/application.properties`.
    *   Update the `spring.datasource.url`, `spring.datasource.username`, and `spring.datasource.password` properties with your MySQL database credentials.
3.  **Configure PayPal:**
    *   Open `src/main/resources/application.properties`.
    *   Update the `paypal.client.id` and `paypal.client.secret` with your PayPal API credentials.
4.  **Build and run the application:**
    ```bash
    ./mvnw spring-boot:run
    ```

## API Documentation

The API documentation is available through Swagger UI. Once the application is running, you can access the interactive documentation at [/swagger-ui.html](http://localhost:8080/swagger-ui.html).

## Payment Testing Material
- PayPal client id = `ASC7o9L-ft-ecQbCXoEhRyor52LOL6tHDohfny89aFDgeN_CzWNOYnQ5o8YLB_dh1qvatW0D9rFxvxK2`
- PayPal client secret = `EAO6HhhcpEeXH4WPGy9pTkttIz3GCt9zTVRX4OMXgCvkcWEjl6_fEK1l8tvHyFrASHEXEmS0rxAiVRWr`
### PayPal user credentials
- Email = `sb-u5pfk47107267@personal.example.com`
- Password = `c^Wxt"R9`

### Testing credit card
- Number = 4020027767454870
- Expiry = 01/2030
- CVV = 927
- Phone = 017889741175
- Country = Berlin
- Street = Lorscher Strasse 4
- Zip code = 60489

### Error simulation cards
https://developer.paypal.com/tools/sandbox/card-testing/#link-simulatecarderrorscenarios