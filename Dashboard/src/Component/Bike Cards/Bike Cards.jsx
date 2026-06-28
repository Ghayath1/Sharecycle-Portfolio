import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardMedia,
  Button,
  CardActions,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import { useNavigate } from 'react-router-dom';
import Bike from '../../assets/Bike.png'; // dein lokales Bild
import { useTranslation } from 'react-i18next';




const BikeCards = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [bikes, setBikes] = useState([]);

  useEffect(() => {
    const fetchBikes = async () => {
      try {
        // Get token from localStorage (adjust if stored elsewhere)
        const token = localStorage.getItem('token');
        const response = await fetch('http://localhost:8080/api/bicycles', {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        });
        if (!response.ok) throw new Error('Failed to fetch bikes');
        const data = await response.json();
        setBikes(data);
      } catch (error) {
        console.error(error);
      }
    };
    fetchBikes();
  }, []);

  const handleEdit = (id) => {
    navigate(`/edit-ad/${id}`);
  };

  return (
    <Box sx={{ p: 4 }}>
      <Grid container spacing={3} justifyContent="center">
        {bikes.map((bike, index) => (
          <Grid item key={bike.id || index} xs={12} sm={6} md={4}>
            <Card
              sx={{
                borderRadius: 2,
                border: '1px solid #ccc',
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
              }}
            >
              <CardMedia
                component="img"
                image={bike.imageUrl || Bike}
                alt={bike.name}
                sx={{
                  height: 200,
                  width: '100%',
                  objectFit: 'cover',
                  backgroundColor: '#f9f9f9',
                  display: 'block',
                  margin: '0 auto',
                }}
              />
              <CardContent sx={{ flexGrow: 1, px: 2 }}>
                <Typography fontWeight="bold" color="#d35400">
                  {bike.name}
                </Typography>
                <Typography color="#d35400" fontWeight="medium">
                  {bike.price} €
                </Typography>
                <Typography color="#d35400">{bike.availableFrom}</Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', color: '#d35400', mt: 1 }}>
                  <LocationOnIcon fontSize="small" />
                  <Typography sx={{ ml: 0.5 }}>{bike.city}</Typography>
                </Box>
                <Typography color="#d35400">{bike.ownerEmail}</Typography>
              </CardContent>
              <CardActions sx={{ justifyContent: 'flex-start', px: 2, pb: 2 }}>
                <Button
                  variant="contained"
                  sx={{
                    backgroundColor: '#d35400',
                    borderRadius: 2,
                    textTransform: 'none',
                    px: 3,
                  }}
                  endIcon={<EditIcon />}
                  onClick={() => handleEdit(bike.id)}
                >
                  {t('Edit')}
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default BikeCards;
