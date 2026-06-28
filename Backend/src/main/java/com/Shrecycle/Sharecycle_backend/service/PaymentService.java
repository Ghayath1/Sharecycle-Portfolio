package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.PaymentDTO;
import com.Shrecycle.Sharecycle_backend.dto.PaymentSummaryDTO;
import com.Shrecycle.Sharecycle_backend.entity.Order;
import com.Shrecycle.Sharecycle_backend.entity.Payment;
import com.Shrecycle.Sharecycle_backend.enums.PaymentStatus;
import com.Shrecycle.Sharecycle_backend.repository.OrderRepository;
import com.Shrecycle.Sharecycle_backend.repository.PaymentRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.paypal.sdk.PaypalServerSdkClient;
import com.paypal.sdk.controllers.OrdersController;
import com.paypal.sdk.controllers.PaymentsController;
import com.paypal.sdk.exceptions.ApiException;
import com.paypal.sdk.http.response.ApiResponse;
import com.paypal.sdk.models.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PaymentService {
    private PaypalServerSdkClient client;
    private PaymentRepository paymentRepository;
    private OrderRepository orderRepository;
    private final ObjectMapper objectMapper;

    @Autowired
    public PaymentService(PaypalServerSdkClient client, PaymentRepository paymentRepository, OrderRepository orderRepository, ObjectMapper objectMapper) {
        this.client = client;
        this.paymentRepository = paymentRepository;
        this.orderRepository = orderRepository;
        this.objectMapper = objectMapper;
    }

    public void addPaymentLog(Payment payment, Object details) {
        try {
            ArrayNode history;
            String currentHistory = payment.getPaymentHistory();
            if (currentHistory == null || currentHistory.trim().isEmpty() || currentHistory.trim().equals("null")) {
                history = objectMapper.createArrayNode();
            } else {
                history = (ArrayNode) objectMapper.readTree(currentHistory);
            }
            history.add(objectMapper.valueToTree(details));
            payment.setPaymentHistory(objectMapper.writeValueAsString(history));
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize payment history", e);
        }
    }

    public void CapturePaymentForOrder(Order order) throws ResponseException, IOException, ApiException {
        if (order.getPayment().getStatus() != PaymentStatus.AUTHORIZED) {
            throw new ResponseException("Payment is not authorized yet!", HttpStatus.CONFLICT.value());
        }

        PaymentsController paymentsController = client.getPaymentsController();
        CaptureAuthorizedPaymentInput captureAuthorizedPaymentInput = new CaptureAuthorizedPaymentInput.Builder(
                order.getPayment().getAuthorizationId(),
                null).build();
        CapturedPayment capturePaymentResponse = paymentsController
                .captureAuthorizedPayment(captureAuthorizedPaymentInput).getResult();
        addPaymentLog(order.getPayment(), capturePaymentResponse);
        if (capturePaymentResponse.getStatus() != CaptureStatus.COMPLETED) {
            throw new ResponseException("Payment capture failed! Check the logs for more details",
                    HttpStatus.BAD_REQUEST.value()
            );
        }

        order.getPayment().setStatus(PaymentStatus.CAPTURED);
        order.getPayment().setCaptureId(capturePaymentResponse.getId());
        paymentRepository.save(order.getPayment());
    }

    public void voidAuthorization(Order order) throws ResponseException, IOException, ApiException {
        if (order.getPayment().getStatus() != PaymentStatus.AUTHORIZED) {
            throw new ResponseException("Payment is not authorized yet!", HttpStatus.CONFLICT.value());
        }

        PaymentsController paymentsController = client.getPaymentsController();
        VoidPaymentInput voidPaymentInput = new VoidPaymentInput.Builder(
                order.getPayment().getAuthorizationId()).build();
        var apiResponse = paymentsController.voidPayment(voidPaymentInput);
        PaymentAuthorization voidedAuth = apiResponse.getResult();
        addPaymentLog(order.getPayment(), voidedAuth);
        if (!List.of(200, 204).contains(apiResponse.getStatusCode())) {
            throw new ResponseException("Voiding failed! Check the logs for more details",
                    HttpStatus.BAD_REQUEST.value()
            );
        }
        order.getPayment().setStatus(PaymentStatus.VOIDED);
        paymentRepository.save(order.getPayment());
    }

    public void save(Payment payment) {
        paymentRepository.save(payment);
    }

    public OrderAuthorizeResponse authorizeOrders(String paypalOrderID) throws IOException, ApiException, ResponseException {
        AuthorizeOrderInput authorizeOrderInput = new AuthorizeOrderInput.Builder(
                paypalOrderID, null).build();
        OrdersController ordersController = client.getOrdersController();
        OrderAuthorizeResponse apiResponse = ordersController.authorizeOrder(authorizeOrderInput).getResult();
        if (apiResponse.getStatus() != OrderStatus.COMPLETED) {
            throw new ResponseException("Payment authorization failed! Check the logs for more details",
                    HttpStatus.BAD_REQUEST.value()
            );
        }

        return apiResponse;
    }

    /**
     * Retrieves all payments with their associated order IDs and amounts.
     * @return A list of PaymentDTO objects.
     */
    public List<PaymentDTO> getAllPayments() {
        List<Order> orders = orderRepository.findAll();
        return orders.stream()
                .map(order -> {
                    Payment payment = order.getPayment();
                    PaymentDTO dto = new PaymentDTO();
                    dto.setId(payment.getId());
                    dto.setOrderId(order.getId());
                    dto.setStatus(payment.getStatus());
                    dto.setPaypalOrderId(payment.getPaypalOrderId());
                    dto.setAuthorizationId(payment.getAuthorizationId());
                    dto.setCaptureId(payment.getCaptureId());
                    dto.setAmount(order.getTotalPrice());
                    return dto;
                })
                .collect(Collectors.toList());
    }

    /**
     * Calculates the total income from all captured payments.
     * Note: Since Payment entity doesn't store the price and has no back-reference to Order,
     * we need to query Orders to get the total price information.
     * @return A PaymentSummaryDTO with the total income.
     */
    public PaymentSummaryDTO getPaymentSummary() {
        List<Order> orders = orderRepository.findAll();
        double totalIncome = orders.stream()
                .filter(order -> order.getPayment() != null && 
                               order.getPayment().getStatus() == PaymentStatus.CAPTURED)
                .mapToDouble(Order::getTotalPrice)
                .sum();
        return new PaymentSummaryDTO(totalIncome);
    }
}
