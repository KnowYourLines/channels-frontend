<template>
  Room members:
  <ul id="array-rendering">
    <li v-for="member in roomMembers" :key="member.display_name">
      {{ member.display_name }}
    </li>
  </ul>
  <span v-if="privateRoom">Users requesting to join:</span>
  <ul id="array-rendering">
    <li v-for="request in joinRequests" :key="request.user">
      {{ request.user__display_name }}
      <div class="btn-group">
        <button
          type="button"
          class="btn"
          @click="acceptRequest(request.user__username)"
        >
          Accept
        </button>
        <button
          type="submit"
          class="btn btn__primary"
          @click="rejectRequest(request.user__username)"
        >
          Reject
        </button>
      </div>
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
    joinRequests: {
      type: Array,
      required: true,
    },
    roomMembers: {
      type: Array,
      required: true,
    },
    privateRoom: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    acceptRequest: function (username) {
      this.socketRef.send(
        JSON.stringify({ command: "approve_user", username: username })
      );
    },
    rejectRequest: function (username) {
      this.socketRef.send(
        JSON.stringify({ command: "reject_user", username: username })
      );
    },
  },
};
</script>
<style >
#array-rendering {
  list-style-type: none;
}
</style>
