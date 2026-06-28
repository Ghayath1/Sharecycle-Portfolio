import React, { useState } from 'react';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';

import {
  Box,
  Grid,
  Typography,
  Radio,
  FormControlLabel,
  RadioGroup,
  Button,
} from '@mui/material';

const paymentMethods = [
  {
    id: 'paypal',
    name: 'Paypal',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/b/b5/PayPal.svg',
  },
  {
    id: 'applepay',
    name: 'Apple Pay',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
  },
  {
    
  id: 'bank',
  name: 'Bank',
  logo: <AccountBalanceIcon sx={{ fontSize: 32, color: '#d35400' }} />,
  },
];

const PaymentOptions = () => {
  const [selectedMethod, setSelectedMethod] = useState('paypal');
  const [status, setStatus] = useState({
    paypal: true,
    applepay: true,
    bank: false,
  });

  const handleRadioChange = (event) => {
    setSelectedMethod(event.target.value);
  };

  const toggleStatus = (id, newState) => {
    setStatus((prev) => ({ ...prev, [id]: newState }));
  };

  return (
    <Box sx={{ p: 4 }}>
      <RadioGroup value={selectedMethod} onChange={handleRadioChange}>
        {paymentMethods.map((method) => (
          <Grid
            key={method.id}
            container
            alignItems="center"
            spacing={2}
            sx={{ mb: 4 }}
          >
            <Grid item>
              <FormControlLabel
                value={method.id}
                control={
                  <Radio
                    sx={{
                      color: '#d35400',
                      '&.Mui-checked': { color: '#d35400' },
                    }}
                  />
                }
                label=""
              />
            </Grid>
            <Grid item>
  {typeof method.logo === 'string' ? (
    <img
      src={method.logo}
      alt={method.name}
      width={60}
      height={30}
      style={{ objectFit: 'contain' }}
    />
  ) : (
    method.logo
  )}
</Grid>

            <Grid item>
              <Typography>{method.name}</Typography>
            </Grid>
            <Grid item sx={{ ml: 'auto' }}>
              <Button
                variant="contained"
                size="small"
                onClick={() => toggleStatus(method.id, true)}
                sx={{
                  backgroundColor: status[method.id] ? '#2ecc71' : '#ccc',
                  color: 'white',
                  textTransform: 'none',
                  mr: 1,
                }}
              >
                ON
              </Button>
              <Button
                variant="contained"
                size="small"
                onClick={() => toggleStatus(method.id, false)}
                sx={{
                  backgroundColor: !status[method.id] ? '#c0392b' : '#ccc',
                  color: 'white',
                  textTransform: 'none',
                }}
              >
                OFF
              </Button>
            </Grid>
          </Grid>
        ))}
      </RadioGroup>
    </Box>
  );
};

export default PaymentOptions;