// src/pages/Dashboard/Index.jsx

import React from 'react';
import { Grid, Box, Container } from '@mui/material';

import Lastorder from '../../Component/LastOrdersTable/LastOrders';
import LastPaymentsTable from '../../Component/LastPaymentsTable/LastPaymentsTable';
import StatCards from '../../Component/StatCards/StatCard';

const Dashboard = () => {
  return (
    <Container maxWidth="xl" sx={{ mt: 4 }}>
      {/* Top Stats Row */}
     

      {/* Main Content Grid */}
      <Grid container columns={12} spacing={2} sx={{ mt: 2 }}>
        {/* Left: Last Orders */}
        <Grid gridColumn="span 8">
          <Lastorder />
        </Grid>

        {/* Right: Stats Cards already rendered above */}

        {/* Right: Last Payments */}
        <Grid gridColumn="span 4">
          <StatCards />
          <LastPaymentsTable />
        </Grid>
      </Grid>
    </Container>
  );
};

export default Dashboard;
