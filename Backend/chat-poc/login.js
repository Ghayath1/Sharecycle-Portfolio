// Configuration
const API_BASE_URL = 'http://localhost:8080';

// Load users on page load
document.addEventListener('DOMContentLoaded', async () => {
    await loadUsers();
});

async function loadUsers() {
    const usersList = document.getElementById('usersList');
    const errorMessage = document.getElementById('errorMessage');
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/user/public/all`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const users = await response.json();
        
        if (users.length === 0) {
            usersList.innerHTML = '<div class="no-users">No users available</div>';
            return;
        }

        usersList.innerHTML = '';
        users.forEach(user => {
            const userCard = createUserCard(user);
            usersList.appendChild(userCard);
        });

    } catch (error) {
        console.error('Error loading users:', error);
        errorMessage.textContent = 'Failed to load users. Make sure the backend is running.';
        usersList.innerHTML = '<div class="error">Failed to load users</div>';
    }
}

function createUserCard(user) {
    const card = document.createElement('div');
    card.className = 'user-card';
    
    const avatar = document.createElement('div');
    avatar.className = 'user-avatar';
    avatar.textContent = getInitials(user.name);
    avatar.style.backgroundColor = getColorForUser(user.id);
    
    const info = document.createElement('div');
    info.className = 'user-info';
    
    const name = document.createElement('div');
    name.className = 'user-name';
    name.textContent = `${user.name}`;
    
    const email = document.createElement('div');
    email.className = 'user-email';
    email.textContent = user.email;
    
    info.appendChild(name);
    info.appendChild(email);
    
    card.appendChild(avatar);
    card.appendChild(info);
    
    card.addEventListener('click', () => loginAsUser(user));
    
    return card;
}

function loginAsUser(user) {
    // Store user info in sessionStorage
    sessionStorage.setItem('currentUser', JSON.stringify(user));
    
    // Redirect to chat page
    window.location.href = 'chat.html';
}

function getInitials(firstName) {
    const first = firstName ? firstName.charAt(0).toUpperCase() : '';
    return first;
}

function getColorForUser(userId) {
    const colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', 
        '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2',
        '#F8B739', '#52B788', '#E76F51', '#2A9D8F'
    ];
    return colors[userId % colors.length];
}
