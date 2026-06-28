import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Grid,
  TextField,
  InputAdornment,
} from '@mui/material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import EuroIcon from '@mui/icons-material/Euro';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import UploadIcon from '@mui/icons-material/Upload';
import { useTranslation } from 'react-i18next';
import Bike from '../../assets/Bike.png';
import { useParams, useNavigate } from 'react-router-dom';



const BikeEditForm = () => {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const [bike, setBike] = useState(null);
  const [form, setForm] = useState({
    name: '',
    price: '',
    availableFrom: '',
    city: '',
    description: '',
    imageUrl: '',
  });
  const [imageFile, setImageFile] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchBike = async () => {
      setLoading(true);
      try {
        const token = localStorage.getItem('token');
        const response = await fetch(`http://localhost:8080/api/bicycles/${id}`, {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        });
        if (!response.ok) throw new Error('Failed to fetch bike');
        const data = await response.json();
        setBike(data);
        setForm({
          name: data.name || '',
          price: data.price || '',
          availableFrom: data.availableFrom || '',
          city: data.city || '',
          description: data.description || '',
          imageUrl: data.imageUrl || '',
        });
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    if (id) fetchBike();
  }, [id]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleImageChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      setImageFile(e.target.files[0]);
      setForm((prev) => ({ ...prev, imageUrl: URL.createObjectURL(e.target.files[0]) }));
    }
  };

  const handleSave = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      let body;
      let headers;
      if (imageFile) {
        body = new FormData();
        body.append('name', form.name);
        body.append('city', form.city);
        body.append('price', form.price);
        body.append('availableFrom', form.availableFrom);
        body.append('description', form.description);
        body.append('imageUrl', imageFile);
        headers = {
          'Authorization': `Bearer ${token}`,
        };
      } else {
        body = new FormData();
        body.append('name', form.name);
        body.append('city', form.city);
        body.append('price', form.price);
        body.append('availableFrom', form.availableFrom);
        body.append('description', form.description);
        headers = {
          'Authorization': `Bearer ${token}`,
        };
      }
      const response = await fetch(`http://localhost:8080/api/bicycles/${id}`, {
        method: 'PUT',
        headers,
        body,
      });
      if (!response.ok) throw new Error('Failed to update bike');
      navigate('/ads');
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => {
    navigate('/ads');
  };

  if (loading) return <Box sx={{ p: 4 }}>{t('Loading...')}</Box>;
  if (!bike) return <Box sx={{ p: 4 }}>{t('No bicycle found for this ID.')}</Box>;

  return (
    <Box sx={{ p: 4 }}>
      <Grid container spacing={4}>
        {/* Left: Image + Buttons */}
        <Grid item xs={12} md={6} sx={{ textAlign: 'center' }}>
          <Box
            component="img"
            src={form.imageUrl || Bike}
            alt="bike"
            sx={{ width: '100%', maxWidth: 400, borderRadius: 2, objectFit: 'cover', height: 300 }}
          />
          <Box sx={{ mt: 2, display: 'flex', justifyContent: 'center', gap: 2 }}>
            <Button
              variant="outlined"
              component="label"
              startIcon={<UploadIcon />}
              sx={{ textTransform: 'none' }}
            >
              {t('Upload')}
              <input type="file" hidden onChange={handleImageChange} />
            </Button>
            <Button
              variant="contained"
              color="error"
              startIcon={<DeleteIcon />}
              sx={{ textTransform: 'none' }}
              onClick={() => setForm((prev) => ({ ...prev, imageUrl: '' }))}
            >
              {t('Remove')}
            </Button>
          </Box>
        </Grid>

        {/* Right: Form Fields */}
        <Grid item xs={12} md={6}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label={t('BikeTitle')}
                name="name"
                value={form.name}
                onChange={handleChange}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label={t('Price')}
                name="price"
                value={form.price}
                onChange={handleChange}
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
              <LocalizationProvider dateAdapter={AdapterDateFns}>
                <DatePicker
                  label={t('Date')}
                  value={form.availableFrom ? new Date(form.availableFrom) : null}
                  onChange={(newValue) => {
                    const formattedDate = newValue ? newValue.toISOString().split('T')[0] : '';
                    setForm(prev => ({ ...prev, availableFrom: formattedDate }));
                  }}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      error: false
                    }
                  }}
                  format="yyyy-MM-dd"
                />
              </LocalizationProvider>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label={t('Location')}
                name="city"
                value={form.city}
                onChange={handleChange}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <LocationOnIcon />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label={t('Description')}
                name="description"
                value={form.description}
                onChange={handleChange}
              />
            </Grid>

            {/* Action Buttons */}
            <Grid item xs={12} sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
              <Button
                variant="contained"
                color="success"
                sx={{ textTransform: 'none', px: 4 }}
                onClick={handleSave}
                startIcon={<EditIcon />}
              >
                {t('Save')}
              </Button>
              <Button
                variant="contained"
                color="error"
                sx={{ textTransform: 'none', px: 4 }}
                endIcon={<DeleteIcon />}
                onClick={handleCancel}
              >
                {t('Cancel')}
              </Button>
            </Grid>
          </Grid>
        </Grid>
      </Grid>
    </Box>
  );
};

export default BikeEditForm;
