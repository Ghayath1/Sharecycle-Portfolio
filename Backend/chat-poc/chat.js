// Configuration
const API_BASE_URL = 'http://localhost:8080';
const WS_URL = 'http://localhost:8080/ws';

// Global variables
let stompClient = null;
let currentUser = null;
let selectedUser = null;
let allUsers = [];
let isConnected = false;

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    // Check if user is logged in
    const userJson = sessionStorage.getItem('currentUser');
    if (!userJson) {
        window.location.href = 'index.html';
        return;
    }
    
    currentUser = JSON.parse(userJson);
    initializeUI();
    await loadUsers();
    connectWebSocket();
    setupEventListeners();
});

function initializeUI() {
    document.getElementById('currentUserName').textContent = 
        `${currentUser.name}`;
    document.getElementById('currentUserId').textContent = `#${currentUser.id}`;
    
    const avatar = document.getElementById('currentUserAvatar');
    avatar.textContent = getInitials(currentUser.name);
    avatar.style.backgroundColor = getColorForUser(currentUser.id);
}

function setupEventListeners() {
    // Logout button
    document.getElementById('logoutBtn').addEventListener('click', logout);
    
    // Close chat button
    document.getElementById('closeChatBtn').addEventListener('click', closeChat);
    
    // Send message button
    document.getElementById('sendBtn').addEventListener('click', sendMessage);
    
    // Message input - send on Enter (but Shift+Enter for new line)
    const messageInput = document.getElementById('messageInput');
    messageInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });
    
    // Auto-resize textarea
    messageInput.addEventListener('input', function() {
        this.style.height = 'auto';
        this.style.height = Math.min(this.scrollHeight, 120) + 'px';
    });
    
    // Search users
    document.getElementById('searchUsers').addEventListener('input', (e) => {
        filterUsers(e.target.value);
    });
}

async function loadUsers() {
    const usersList = document.getElementById('usersList');
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/user/public/all`);
        if (!response.ok) throw new Error('Failed to load users');
        
        const users = await response.json();
        allUsers = users.filter(u => u.id !== currentUser.id);
        
        renderUsers(allUsers);
    } catch (error) {
        console.error('Error loading users:', error);
        usersList.innerHTML = '<div class="error">Failed to load users</div>';
    }
}

function renderUsers(users) {
    const usersList = document.getElementById('usersList');
    
    if (users.length === 0) {
        usersList.innerHTML = '<div class="no-users">No other users available</div>';
        return;
    }
    
    usersList.innerHTML = '';
    users.forEach(user => {
        const userItem = createUserItem(user);
        usersList.appendChild(userItem);
    });
}

function createUserItem(user) {
    const item = document.createElement('div');
    item.className = 'user-item';
    if (selectedUser && selectedUser.id === user.id) {
        item.classList.add('active');
    }
    
    const avatar = document.createElement('div');
    avatar.className = 'user-avatar';
    avatar.textContent = getInitials(user.firstName, user.lastName);
    avatar.style.backgroundColor = getColorForUser(user.id);
    
    const info = document.createElement('div');
    info.className = 'user-info';
    
    const name = document.createElement('div');
    name.className = 'user-name';
    name.textContent = `${user.firstName} ${user.lastName}`;
    
    const email = document.createElement('div');
    email.className = 'user-email';
    email.textContent = user.email;
    
    info.appendChild(name);
    info.appendChild(email);
    
    item.appendChild(avatar);
    item.appendChild(info);
    
    item.addEventListener('click', () => selectUser(user));
    
    return item;
}

function filterUsers(searchTerm) {
    const filtered = allUsers.filter(user => {
        const fullName = `${user.firstName} ${user.lastName}`.toLowerCase();
        const email = user.email.toLowerCase();
        const term = searchTerm.toLowerCase();
        return fullName.includes(term) || email.includes(term);
    });
    renderUsers(filtered);
}

async function selectUser(user) {
    selectedUser = user;
    
    // Update UI
    document.getElementById('chatPlaceholder').style.display = 'none';
    document.getElementById('chatActive').style.display = 'flex';
    
    // Update chat header
    document.getElementById('chatUserName').textContent = 
        `${user.firstName} ${user.lastName}`;
    const chatAvatar = document.getElementById('chatUserAvatar');
    chatAvatar.textContent = getInitials(user.firstName, user.lastName);
    chatAvatar.style.backgroundColor = getColorForUser(user.id);
    
    // Update active user in sidebar
    document.querySelectorAll('.user-item').forEach(item => {
        item.classList.remove('active');
    });
    event.currentTarget.classList.add('active');
    
    // Load messages
    await loadMessages(user.id);
}

async function loadMessages(otherUserId) {
    const container = document.getElementById('messagesContainer');
    container.innerHTML = '<div class="loading-messages">Loading messages...</div>';
    
    try {
        const response = await fetch(
            `${API_BASE_URL}/messages/${currentUser.id}/${otherUserId}`
        );
        
        if (!response.ok) throw new Error('Failed to load messages');
        
        const messages = await response.json();
        displayMessages(messages);
    } catch (error) {
        console.error('Error loading messages:', error);
        container.innerHTML = '<div class="error">Failed to load messages</div>';
    }
}

function displayMessages(messages) {
    const container = document.getElementById('messagesContainer');
    container.innerHTML = '';
    
    if (messages.length === 0) {
        container.innerHTML = '<div class="no-messages">No messages yet. Start the conversation!</div>';
        return;
    }
    
    messages.forEach(message => {
        appendMessage(message, false);
    });
    
    scrollToBottom();
}

function appendMessage(message, animate = true) {
    const container = document.getElementById('messagesContainer');
    
    // Remove "no messages" placeholder if exists
    const noMessages = container.querySelector('.no-messages');
    if (noMessages) {
        noMessages.remove();
    }
    
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${message.senderId === currentUser.id ? 'sent' : 'received'}`;
    if (animate) {
        messageDiv.classList.add('message-animate');
    }
    
    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';
    
    const content = document.createElement('div');
    content.className = 'message-content';
    content.textContent = message.content;
    
    const time = document.createElement('div');
    time.className = 'message-time';
    time.textContent = formatTime(message.createdAt);
    
    bubble.appendChild(content);
    bubble.appendChild(time);
    messageDiv.appendChild(bubble);
    
    container.appendChild(messageDiv);
    
    if (animate) {
        scrollToBottom();
    }
}

function connectWebSocket() {
    const socket = new SockJS(WS_URL);
    stompClient = Stomp.over(socket);
    
    // Disable debug logging
    stompClient.debug = null;
    
    stompClient.connect({}, onConnected, onError);
}

function onConnected() {
    isConnected = true;
    updateConnectionStatus('Connected', true);
    
    // Subscribe to personal message queue
    stompClient.subscribe(`/user/${currentUser.id}/queue/messages`, onMessageReceived);
    
    console.log('WebSocket connected');
}

function onError(error) {
    isConnected = false;
    updateConnectionStatus('Disconnected', false);
    console.error('WebSocket error:', error);
    
    // Try to reconnect after 5 seconds
    setTimeout(() => {
        console.log('Attempting to reconnect...');
        connectWebSocket();
    }, 5000);
}

function onMessageReceived(payload) {
    const message = JSON.parse(payload.body);
    
    // Only display if the message is part of current conversation
    if (selectedUser && 
        ((message.senderId === selectedUser.id && message.receiverId === currentUser.id) ||
         (message.senderId === currentUser.id && message.receiverId === selectedUser.id))) {
        appendMessage(message, true);
    }
}

function sendMessage() {
    const input = document.getElementById('messageInput');
    const content = input.value.trim();
    
    if (!content || !selectedUser || !isConnected) {
        return;
    }
    
    const message = {
        senderId: currentUser.id,
        receiverId: selectedUser.id,
        content: content,
        type: 'CHAT'
    };
    
    stompClient.send('/app/chat.sendMessage', {}, JSON.stringify(message));
    
    // Clear input
    input.value = '';
    input.style.height = 'auto';
    input.focus();
}

function updateConnectionStatus(status, connected) {
    const statusElement = document.getElementById('connectionStatus');
    const statusDot = document.querySelector('.status-dot');
    
    statusElement.textContent = status;
    
    if (connected) {
        statusDot.classList.add('online');
        statusDot.classList.remove('offline');
    } else {
        statusDot.classList.add('offline');
        statusDot.classList.remove('online');
    }
}

function closeChat() {
    selectedUser = null;
    document.getElementById('chatPlaceholder').style.display = 'flex';
    document.getElementById('chatActive').style.display = 'none';
    
    // Remove active state from all users
    document.querySelectorAll('.user-item').forEach(item => {
        item.classList.remove('active');
    });
}

function logout() {
    if (stompClient && isConnected) {
        stompClient.disconnect();
    }
    sessionStorage.removeItem('currentUser');
    window.location.href = 'index.html';
}

function scrollToBottom() {
    const container = document.getElementById('messagesContainer');
    container.scrollTop = container.scrollHeight;
}

function formatTime(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    
    // If today, show time
    if (diff < 86400000 && date.getDate() === now.getDate()) {
        return date.toLocaleTimeString('en-US', { 
            hour: '2-digit', 
            minute: '2-digit' 
        });
    }
    
    // If yesterday
    if (diff < 172800000 && date.getDate() === now.getDate() - 1) {
        return 'Yesterday';
    }
    
    // Otherwise show date
    return date.toLocaleDateString('en-US', { 
        month: 'short', 
        day: 'numeric' 
    });
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

// Handle page unload
window.addEventListener('beforeunload', () => {
    if (stompClient && isConnected) {
        stompClient.disconnect();
    }
});
