<template>
  <span>Your chatrooms:</span>
  <ul id="array-rendering">
    <li v-for="notification in notifications" :key="notification.room">
      <div v-if="notification.read" class="read-notification">
        <ChatNotification :notification="notification" :socketRef="socketRef" />
      </div>
      <div v-else class="unread-notification">
        <ChatNotification :notification="notification" :socketRef="socketRef" />
      </div>
      <br />
    </li>
  </ul>
</template>
<script>
import ChatNotification from "./ChatNotification.vue";
export default {
  name: "ChatHistory",
  components: {
    ChatNotification,
  },
  props: {
    socketRef: {
      type: WebSocket,
      required: false,
    },
    notifications: {
      type: Array,
      required: true,
    },
  },
};
</script>
<style >
.unread-notification {
  background-color: #5dbeff;
}
#array-rendering {
  list-style-type: none;
}
</style>
