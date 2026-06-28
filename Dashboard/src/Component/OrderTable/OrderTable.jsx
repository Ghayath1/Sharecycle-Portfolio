import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  TableHead,
  Paper,
} from '@mui/material';
import { useTranslation } from 'react-i18next'; // Import i18n




const OrderTable = () => {
  const { t } = useTranslation();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const token = localStorage.getItem("token");

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const response = await fetch('http://localhost:8080/api/orders/admin', {
          headers: {
            'Content-Type': 'application/json',
            // Add Authorization header if needed:
            'Authorization': `Bearer ${token}`,
          },
        });
        if (!response.ok) throw new Error('Failed to fetch orders');
        const data = await response.json();
        setOrders(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchOrders();
  }, []);

  return (
    <Box sx={{ mt: 6, px: 3, textAlign: 'center' }}>
      <Box
        sx={{
          display: 'inline-block',
          backgroundColor: '#d35400',
          color: 'white',
          fontWeight: 'bold',
          px: 4,
          py: 1,
          borderRadius: '8px',
          mb: 4,
        }}
      >
        <Typography variant="h5">{t('Orders')}</Typography>
      </Box>

      {loading ? (
        <Typography>{t('Loading...')}</Typography>
      ) : error ? (
        <Typography color="error">{error}</Typography>
      ) : (
        <Box sx={{ overflowX: 'auto' }}>
          <TableContainer
            component={Paper}
            sx={{
              border: '1px solid #d35400',
              borderRadius: 2,
              minWidth: 650,
            }}
          >
            <Table>
              <TableHead>
                <TableRow>
                  {[t('Customer Name'), t('Order ID'), t('Vendor ID'), t('Start Date'), t('End Date'), t('Order Date'), t('Price'), t('Status')].map((header) => (
                    <TableCell key={header} sx={{ fontWeight: 'bold' }}>
                      {header}
                    </TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {orders.map((row, index) => (
                  <TableRow
                    key={row.orderId || index}
                    sx={{ backgroundColor: index % 2 === 0 ? '#efb197' : 'inherit' }}
                  >
                    <TableCell>{row.customerName}</TableCell>
                    <TableCell>{row.orderId}</TableCell>
                    <TableCell>{row.vendorId}</TableCell>
                    <TableCell>{row.dateFrom}</TableCell>
                    <TableCell>{row.dateTo}</TableCell>
                    <TableCell>{row.orderDate}</TableCell>
                    <TableCell>{row.price}</TableCell>
                    <TableCell>{row.status}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      )}
    </Box>
  );
};

export default OrderTable;
