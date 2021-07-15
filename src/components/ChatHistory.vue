<template>
  <span>Your chatrooms:</span>
  <ul id="array-rendering">
    <li v-for="notification in notifications" :key="notification.room">
      <div v-if="notification.read" class="read-notification">
        <button type="button" class="btn" @click="visitRoom(notification.room)">
          {{ notification.room__display_name }}</button
        ><br />
        <span v-if="notification.message__user__display_name">
          {{ notification.message__user__display_name }} :
          {{ notification.message__content }}</span
        >
        <span v-if="notification.user_joined__display_name">
          {{ notification.user_joined__display_name }} has joined the chat</span
        ><span v-if="notification.user_left__display_name">
          {{ notification.user_left__display_name }} has left the chat</span
        >
        <br />{{ notification.timestamp }}
        <br />
        <button
          type="submit"
          class="btn btn__primary"
          @click="exitRoom(notification.room)"
        >
          Exit room
        </button>
      </div>
      <div v-else class="unread-notification">
        <button type="button" class="btn" @click="visitRoom(notification.room)">
          {{ notification.room__display_name }}</button
        ><br />
        <span v-if="notification.message__user__display_name">
          {{ notification.message__user__display_name }} :
          {{ notification.message__content }}</span
        >
        <span v-if="notification.user_joined__display_name">
          {{ notification.user_joined__display_name }} has joined the chat</span
        ><span v-if="notification.user_left__display_name">
          {{ notification.user_left__display_name }} has left the chat</span
        ><br />{{ notification.timestamp }}
        <br />
        <button
          type="submit"
          class="btn btn__primary"
          @click="exitRoom(notification.room)"
        >
          Exit room
        </button>
      </div>
      <br />
    </li>
  </ul>
</template>
<script>
export default {
  name: "ChatHistory",
  props: {
    socketRef: {
      type: WebSocket,
      required: true,
    },
    notifications: {
      type: Array,
      required: true,
    },
  },
  methods: {
    visitRoom: function (room) {
      let url = new URL(window.location.href);
      url.searchParams.set("room", room);
      window.location.href = url;
    },
    exitRoom: function (room) {
      this.socketRef.send(
        JSON.stringify({ command: "exit_room", room_id: room })
      );
      const urlParams = new URLSearchParams(window.location.search);
      let currentRoom = urlParams.get("room");
      if (room == currentRoom) {
        window.location.href = window.location.href.split("?")[0];
      }
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
