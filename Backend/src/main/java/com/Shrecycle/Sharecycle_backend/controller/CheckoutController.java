package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.OrderRequestDTO;
import com.Shrecycle.Sharecycle_backend.dto.OrderResponseDTO;
import com.Shrecycle.Sharecycle_backend.dto.PayResponseDTO;
import com.Shrecycle.Sharecycle_backend.entity.Payment;
import com.Shrecycle.Sharecycle_backend.enums.PaymentStatus;
import com.Shrecycle.Sharecycle_backend.service.OrderService;
import com.Shrecycle.Sharecycle_backend.service.PaymentService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.paypal.sdk.PaypalServerSdkClient;
import com.paypal.sdk.controllers.OrdersController;
import com.paypal.sdk.controllers.PaymentsController;
import com.paypal.sdk.exceptions.ApiException;
import com.paypal.sdk.http.response.ApiResponse;
import com.paypal.sdk.models.*;
import io.swagger.v3.oas.annotations.Operation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/payment/orders")
//TODO: Complete the business logic
public class CheckoutController {
    private final String returnUrl = "https://whatever-admin-frontend.com/checkout/success";
    private final String cancelUrl = "https://whatever-admin-frontend.com/checkout/cancel";
    private final PaypalServerSdkClient client;
    private final OrderService orderService;
    private final PaymentService paymentService;

    @Autowired
    public CheckoutController(PaypalServerSdkClient client, OrderService orderService, PaymentService paymentService) {
        this.client = client;
        this.orderService = orderService;
        this.paymentService = paymentService;
    }

    @Operation(
            summary = "Step 1: Create a PayPal Order and Get Approval URL",
            description = """
            Initiates the payment process for a bicycle rental.

            This endpoint performs two main actions:
            1.  Creates a corresponding **Order entity** within our system with a `PENDING` status.
            2.  Creates a secure **Order with PayPal** and returns a unique `approvalUrl`.

            The frontend should then redirect the user to this `approvalUrl` to approve the payment on PayPal's website.
            """
    )
    @PostMapping
    public ResponseEntity<PayResponseDTO> pay(@RequestBody OrderRequestDTO request, @AuthenticationPrincipal UserDetails userDetails) {
        try {
            orderService.verifyOrder(request);
            Order paypalOrder = createOrder(request);
            com.Shrecycle.Sharecycle_backend.entity.Order order = orderService.createOrder(request, userDetails.getUsername());
            paymentService.addPaymentLog(order.getPayment(), paypalOrder);
            order.getPayment().setPaypalOrderId(paypalOrder.getId());
            paymentService.save(order.getPayment());

            return new ResponseEntity<>(
                    new PayResponseDTO(
                            paypalOrder.getLinks()
                                    .stream()
                                    .filter(link -> link.getRel().equals("payer-action"))
                                    .findFirst()
                                    .get()
                                    .getHref(),
                            paypalOrder.getId()),
                    HttpStatus.CREATED);
        } catch (Exception e) {
            e.printStackTrace();
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private Order createOrder(OrderRequestDTO request) throws IOException, ApiException, ResponseException {
        CreateOrderInput createOrderInput = new CreateOrderInput.Builder(
                null,
                new OrderRequest.Builder(
                        CheckoutPaymentIntent.AUTHORIZE,
                        Collections.singletonList(
                                orderService.createPurchaseUnitRequestByOrderRequest(request)
                        )
                ).paymentSource(
                        new PaymentSource.Builder()
                                .paypal(
                                        new PaypalWallet.Builder()
                                                .experienceContext(
                                                        new PaypalWalletExperienceContext.Builder()
                                                                .userAction(PaypalExperienceUserAction.CONTINUE)
                                                                .returnUrl(returnUrl)
                                                                .cancelUrl(cancelUrl)
                                                                .build()
                                                ).build()
                                ).build()
                ).build()
        ).build();
        OrdersController ordersController = client.getOrdersController();
        Order paypalOrder = ordersController.createOrder(createOrderInput).getResult();

        if (paypalOrder.getStatus() != OrderStatus.PAYER_ACTION_REQUIRED) {
            throw new ResponseException("Order could not be created: " + paypalOrder.getStatus(),
                    HttpStatus.BAD_REQUEST.value()
            );
        }

        return paypalOrder;
    }

    @Operation(
            summary = "Step 2: Authorize Payment After User Approval",
            description = """
            This endpoint should be called by the frontend immediately after the user approves the payment on PayPal and is redirected back to the application.

            It finalizes the pre-approved payment:
            1.  It calls PayPal's API to officially **authorize** the transaction using the `paypalOrderID`.
            2.  It retrieves the unique `authorizationId` from PayPal.
            3.  The **Payment Status** in our database is updated from `INITIALIZED` to `AUTHORIZED`, and the `authorizationId` is stored for future use (i.e., for capturing the funds or voiding authorization).

            This action places a hold on the user's funds, which is valid for 29 days.
            """
    )
    @PostMapping("/{paypalOrderID}/authorize")
    public ResponseEntity<OrderResponseDTO> authorizeOrder(
            @PathVariable String paypalOrderID,
            @AuthenticationPrincipal UserDetails userDetails
    ) throws IOException, ApiException {
        System.out.println("authorizeOrder");
        try {
            com.Shrecycle.Sharecycle_backend.entity.Order order = this.orderService.getOrderByPaypalOrderId(paypalOrderID);
            if (!order.getRenter().getEmail().equals(userDetails.getUsername())) {
                throw new SecurityException("Not allowed to view this order");
            }
            Payment payment = order.getPayment();
            OrderAuthorizeResponse response = paymentService.authorizeOrders(paypalOrderID);
            paymentService.addPaymentLog(payment, response);
            payment.setStatus(PaymentStatus.AUTHORIZED);
            payment.setAuthorizationId(response.getPurchaseUnits().get(0).getPayments().getAuthorizations().get(0).getId());
            paymentService.save(payment);

            return new ResponseEntity<>(
                    orderService.getOrderResponseDtoByIdAndEmail(order.getId(), userDetails.getUsername()),
                    HttpStatus.OK
            );
        } catch (Exception e) {
            e.printStackTrace();
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    public Order getCompletePaypalOrderDetails(String orderId) throws IOException, ApiException {
        OrdersController ordersController = client.getOrdersController();
        return ordersController.getOrder(new GetOrderInput.Builder(orderId).build()).getResult();
    }
}
