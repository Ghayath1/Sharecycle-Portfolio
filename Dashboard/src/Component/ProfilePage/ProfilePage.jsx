import React, { useState, useEffect } from 'react';
import {
  Avatar,
  Box,
  Button,
  Grid,
  InputAdornment,
  Paper,
  TextField,
  Typography,
  useTheme,
  useMediaQuery,
  CircularProgress,
  Snackbar,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';

import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import PersonIcon from '@mui/icons-material/Person';
import EmailIcon from '@mui/icons-material/Email';
import PhoneIcon from '@mui/icons-material/Phone';
import LockIcon from '@mui/icons-material/Lock';
import { useTranslation } from 'react-i18next';

const fieldStyle = {
  backgroundColor: '#c64a00',
  borderRadius: 2,
  '& input': { color: 'white' },
  '& .MuiInputLabel-root': { color: 'white' },
  '& .MuiOutlinedInput-notchedOutline': { border: 'none' },
};

const BACKEND_URL = 'http://localhost:8080';

const ProfilePage = () => {
  const { t } = useTranslation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [profileData, setProfileData] = useState({
    username: '',
    email: '',
    iphoneNumber: '',
    birthDate: '',
    imageUrl: '',
    selectedImage: null // for storing the selected image file
  });

  useEffect(() => {
    fetchProfile();
  }, []);
  useEffect(() => {
    const currentImageUrl = profileData.imageUrl;
    // Cleanup function to revoke the object URL
    return () => {
      if (currentImageUrl && currentImageUrl.startsWith('blob:')) {
        URL.revokeObjectURL(currentImageUrl);
      }
    };
  }, [profileData.imageUrl]);

  const fetchProfile = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`${BACKEND_URL}/api/admins/profile`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Failed to fetch profile');
      }

      const data = await response.json();
      setProfileData(data);
    } catch (error) {
      console.error('Error fetching profile:', error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field) => (event) => {
    setProfileData(prev => ({
      ...prev,
      [field]: event.target.value
    }));
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      setError(null);

      const formData = new FormData();
      if (profileData.username) formData.append('username', profileData.username);
      if (profileData.email) formData.append('email', profileData.email);
      if (profileData.iphoneNumber) formData.append('iphoneNumber', profileData.iphoneNumber);
      if (profileData.birthDate) formData.append('birthDate', profileData.birthDate);
      if (profileData.selectedImage) formData.append('image', profileData.selectedImage);

      const response = await fetch(`${BACKEND_URL}/api/admins/profile`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: formData
      });

      if (!response.ok) {
        throw new Error('Failed to update profile');
      }

      const updatedData = await response.json();
      setProfileData(prev => ({
        ...prev,
        ...updatedData,
        imageUrl: updatedData.imageUrl,
        selectedImage: null // Clear the selected image after successful update
      }));
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (error) {
      console.error('Error updating profile:', error);
      setError(error.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`${BACKEND_URL}/api/admins/delete/${profileData.id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Failed to delete account');
      }

      // Clear token and redirect to login
      localStorage.removeItem('token');
      window.location.href = '/login';
    } catch (error) {
      console.error('Error deleting account:', error);
      setError(error.message);
    } finally {
      setLoading(false);
      setDeleteDialogOpen(false);
    }
  };

  return (
    <Box sx={{ backgroundColor: '#eee', minHeight: '100vh', p: 2 }}>
      <Box sx={{ maxWidth: 1200, mx: 'auto' }}>
        {loading ? (
          <Box display="flex" justifyContent="center" alignItems="center" height="50vh">
            <CircularProgress />
          </Box>
        ) : (
          <Grid
            container
            spacing={4}
            justifyContent="center"
            alignItems="flex-start"
            direction={isMobile ? 'column' : 'row'}
          >
            {/* Left Section: Avatar */}
            <Grid item xs={12} md={4}>
              <Paper
                elevation={3}
                sx={{
                  borderRadius: 4,
                  p: 4,
                  textAlign: 'center',
                  maxWidth: 360,
                  mx: 'auto',
                }}
              >
                <Avatar
                  src={
                    profileData.imageUrl
                      ? profileData.imageUrl.startsWith('blob:')
                        ? profileData.imageUrl // Use local blob URL directly
                        : `${BACKEND_URL}${profileData.imageUrl}` // Use backend path
                      : '' // No image
                  }
                  alt="Profile"
                  sx={{ width: 150, height: 150, mx: 'auto', mb: 2 }}
                />
                <input
                  type="file"
                  accept="image/*"
                  style={{ display: 'none' }}
                  id="avatar-upload"
                  onChange={(e) => {
                    const file = e.target.files[0];
                    if (file) {
                      const newPreviewUrl = URL.createObjectURL(file);
                      setProfileData(prev => {
                        // Revoke old blob URL if it exists
                        if (prev.imageUrl && prev.imageUrl.startsWith('blob:')) {
                          URL.revokeObjectURL(prev.imageUrl);
                        }
                        return {
                          ...prev,
                          selectedImage: file,
                          imageUrl: newPreviewUrl // Set new blob URL for preview
                        };
                      });
                    }
                  }}
                />
                <label htmlFor="avatar-upload">
                  <Button
                    variant="contained"
                    component="span"
                    sx={{
                      backgroundColor: '#d35400',
                      '&:hover': { backgroundColor: '#e36b17' },
                      textTransform: 'none',
                      borderRadius: 2,
                      px: 4,
                    }}
                    endIcon={<EditIcon />}
                  >
                    {t('Edit')}
                  </Button>
                </label>
              </Paper>
            </Grid>

            {/* Right Section: Form */}
            <Grid item xs={12} md={8}>
              <Paper
                elevation={3}
                sx={{
                  borderRadius: 4,
                  p: 4,
                  mx: 'auto',
                  maxWidth: 600,
                  width: '60%',
                  mt: isMobile ? 4 : 0,
                  backgroundColor: '#fff',
                  overflow: 'hidden',
                }}
              >
                <Typography variant="h6" fontWeight="bold" mb={3}>
                  {t('Profile')}
                </Typography>

                <Grid container spacing={2}>
                  {[
                    { field: 'name', label: t('Name'), icon: <PersonIcon />, value: profileData.username },
                    { field: 'email', label: t('Email'), icon: <EmailIcon />, value: profileData.email },
                    { field: 'iphoneNumber', label: t('PhoneNumber'), icon: <PhoneIcon />, value: profileData.iphoneNumber },
                    { field: 'birthDate', label: t('BirthDate'), icon: <PersonIcon />, value: profileData.birthDate, type: 'date' },
                  ].map((field, index) => (
                    <Grid item xs={12} key={index}>
                      <TextField
                        fullWidth
                        label={field.label}
                        type={field.type || 'text'}
                        value={field.value || ''}
                        onChange={handleInputChange(field.field)}
                        InputProps={{
                          endAdornment: field.icon ? (
                            <InputAdornment position="end">{field.icon}</InputAdornment>
                          ) : null,
                          sx: fieldStyle,
                        }}
                      />
                    </Grid>
                  ))}

                  <Grid item xs={12}>
                    <Box sx={{ display: 'flex', gap: 2 }}>
                      <Button
                        variant="contained"
                        sx={{
                          flex: 1,
                          height: '56px',
                          backgroundColor: '#2ecc71',
                          color: 'white',
                          textTransform: 'none',
                          fontWeight: 'bold',
                          '&:hover': { backgroundColor: '#27ae60' },
                        }}
                        endIcon={saving ? <CircularProgress size={20} color="inherit" /> : <EditIcon />}
                        onClick={handleSave}
                        disabled={saving}
                      >
                        {t('Save')}
                      </Button>
                      <Button
                        variant="contained"
                        sx={{
                          flex: 1,
                          height: '56px',
                          backgroundColor: 'red',
                          color: 'white',
                          textTransform: 'none',
                          fontWeight: 'bold',
                          '&:hover': { backgroundColor: '#c0392b' },
                        }}
                        startIcon={<DeleteIcon />}
                        onClick={() => setDeleteDialogOpen(true)}
                      >
                        {t('Delete')}
                      </Button>
                    </Box>
                  </Grid>
                </Grid>
              </Paper>
            </Grid>
          </Grid>
        )}
      </Box>

      {/* Delete Account Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>{t('DeleteAccount')}</DialogTitle>
        <DialogContent>
          <DialogContentText>
            {t('DeleteAccountConfirmation')}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>{t('Cancel')}</Button>
          <Button onClick={handleDelete} color="error" autoFocus>
            {t('Delete')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Success Message */}
      <Snackbar
        open={success}
        autoHideDuration={3000}
        onClose={() => setSuccess(false)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert severity="success" variant="filled">
          {profileData.selectedImage ? t('ProfileAndImageUpdated') : t('ProfileUpdated')}
        </Alert>
      </Snackbar>

      {/* Error Message */}
      <Snackbar
        open={!!error}
        autoHideDuration={3000}
        onClose={() => setError(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert severity="error" variant="filled">
          {error}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default ProfilePage;
