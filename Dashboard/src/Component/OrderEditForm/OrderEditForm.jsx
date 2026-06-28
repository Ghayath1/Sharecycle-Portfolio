import React, { useState, useEffect } from 'react';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import {
  Box,
  Grid,
  TextField,
  Avatar,
  Typography,
  InputAdornment,
  Button,
  Divider, // Import Divider for horizontal separator
  CircularProgress, // For loading indicator
  Alert, // For error messages
} from '@mui/material';
import EuroIcon from '@mui/icons-material/Euro';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import EditIcon from '@mui/icons-material/Edit';
import CloseIcon from '@mui/icons-material/Close';
import { useTranslation } from 'react-i18next';
import BikePlaceholder from '../../assets/Bike3.avif'; // Using a placeholder image

const API_BASE = 'http://localhost:8080';

const OrderEditForm = () => {
  const { t } = useTranslation();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const token = localStorage.getItem('token'); // Assuming token is stored in localStorage
        const response = await fetch(`${API_BASE}/api/orders/admin`, {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        });
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        setOrders(
          data.map((order) => ({
            ...order,
            dateFrom: new Date(order.dateFrom),
            dateTo: new Date(order.dateTo),
          }))
        );
      } catch (error) {
        setError(error);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, []);

  const handleDateChange = (orderId, field, date) => {
    setOrders((prevOrders) =>
      prevOrders.map((order) =>
        order.orderId === orderId ? { ...order, [field]: date } : order
      )
    );
  };

  const handleUpdateOrder = async (orderId) => {
    const order = orders.find((o) => o.orderId === orderId);
    if (!order) return;

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`${API_BASE}/api/orders/admin/${orderId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          bicycleId: order.bikeId,
          dateFrom: order.dateFrom.toISOString().split('T')[0],
          dateTo: order.dateTo.toISOString().split('T')[0],
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      setSuccessMessage('Order updated successfully!');
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (error) {
      setError(error);
      setTimeout(() => setError(null), 3000);
    }
  };

  const handleCancelOrder = async (orderId) => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`${API_BASE}/api/orders/admin/${orderId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      setOrders((prevOrders) => prevOrders.filter((order) => order.orderId !== orderId));
      setSuccessMessage('Order canceled successfully!');
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (error) {
      setError(error);
      setTimeout(() => setError(null), 3000);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 4 }}>
        <Alert severity="error">Error: {error.message}</Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 4 }}>
      {successMessage && <Alert severity="success">{successMessage}</Alert>}
      {orders.length === 0 ? (
        <Typography variant="h6" sx={{ textAlign: 'center' }}>
          {t('No orders found.')}
        </Typography>
      ) : (
        orders.map((order, index) => (
          <React.Fragment key={order.orderId}>
            <Grid container spacing={2} sx={{ mb: 4 }}>
              {/* Bicycle Information (Image, Title, Price, Location) */}
              <Grid item xs={12} container spacing={2} alignItems="end">
                <Grid item xs={12} md={9}>
                  <Grid container spacing={2} alignItems="center">
                    <Box
                      component="img"
                      src={API_BASE + order.bikeImageUrl || BikePlaceholder}
                      alt={order.bikeName || 'Bike'}
                      sx={{ width: '20%', borderRadius: 2 }}
                    />
                    <Grid item xs={12}>
                      <TextField fullWidth label={t('Bike Title')} value={order.bikeName || ''} disabled />
                    </Grid>
                    <Grid item xs={12}>
                      <TextField
                        fullWidth
                        label={t('Price')}
                        value={order.bikePrice || ''}
                        disabled
                        InputProps={{
                          endAdornment: (
                            <InputAdornment position="end">
                              <EuroIcon sx={{ color: '#d35400' }} />
                            </InputAdornment>
                          ),
                        }}
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <TextField
                        fullWidth
                        label={t('Location')}
                        value={order.bikeCity || ''}
                        disabled
                        InputProps={{
                          endAdornment: (
                            <InputAdornment position="end">
                              <LocationOnIcon sx={{ color: '#d35400' }} />
                            </InputAdornment>
                          ),
                        }}
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <TextField fullWidth label={t('Order Date')} value={order.orderDate || ''} disabled />
                    </Grid>
                  </Grid>
                </Grid>
              </Grid>

              {/* Order Information (Order Date, Customer, Vendor, Dates, Payment Method, Action Buttons) */}
              <Grid item xs={12}>
                <Grid container spacing={2}>
                  {/* Customer & Vendor */}
                  <Grid item xs={12} md={6}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar src={order.customerProfileImage || "https://randomuser.me/api/portraits/men/8.jpg"} />
                      <TextField value={order.customerName || ''} label={t('Customer')} disabled />
                      <TextField value={order.customerId || ''} label={t('ID')} sx={{ width: 60 }} disabled />
                    </Box>
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar src={order.vendorProfileImage || "https://randomuser.me/api/portraits/men/9.jpg"} />
                      <TextField value={order.vendorName || ''} label={t('Vendor')} disabled />
                      <TextField value={order.vendorId || ''} label={t('ID')} sx={{ width: 60 }} disabled />
                    </Box>
                  </Grid>

                  {/* Dates */}
                  <Grid item xs={12} md={4}>
                    <DatePicker
                      selected={order.dateFrom}
                      onChange={(date) => handleDateChange(order.orderId, 'dateFrom', date)}
                      customInput={<TextField fullWidth label={t('Start Date')} />}
                    />
                  </Grid>
                  <Grid item xs={12} md={4}>
                    <DatePicker
                      selected={order.dateTo}
                      onChange={(date) => handleDateChange(order.orderId, 'dateTo', date)}
                      customInput={<TextField fullWidth label={t('End Date')} />}
                    />
                  </Grid>

                  {/* Payment Method */}
                  <Grid item xs={12} md={4}>
                    <Box
                      sx={{
                        display: 'flex',
                        alignItems: 'center',
                        border: '1px solid #ddd',
                        borderRadius: 2,
                        p: 1.5,
                        height: '30px',
                      }}
                    >
                      <img
                        src="https://upload.wikimedia.org/wikipedia/commons/b/b5/PayPal.svg"
                        alt="PayPal"
                        width={50}
                        height={24}
                      />
                      <Typography sx={{ ml: 2 }}>{t('Paypal')}</Typography>
                    </Box>
                  </Grid>

                  {/* Action Buttons */}
                  <Grid item xs={12} sx={{ textAlign: 'right', mt: 3 }}>
                    <Button
                      variant="contained"
                      startIcon={<EditIcon />}
                      sx={{
                        backgroundColor: '#7f8c8d',
                        color: 'white',
                        textTransform: 'none',
                        mr: 2,
                      }}
                      onClick={() => handleUpdateOrder(order.orderId)}
                    >
                      {t('Edit Order')}
                    </Button>
                    <Button
                      variant="contained"
                      color="error"
                      endIcon={<CloseIcon />}
                      sx={{ textTransform: 'none' }}
                      onClick={() => handleCancelOrder(order.orderId)}
                    >
                      {t('Cancel Order')}
                    </Button>
                  </Grid>
                </Grid>
              </Grid>
            </Grid>
            {index < orders.length - 1 && <Divider sx={{ my: 4 }} />}
          </React.Fragment>
        ))
      )}
    </Box>
  );
};

export default OrderEditForm;
