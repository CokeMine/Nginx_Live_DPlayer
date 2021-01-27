const Koa = require('koa');
const koaStatic = require('koa-static');
const path = require('path');
const app = new Koa();
const server = require('http').createServer(app.callback());
const {Server} = require('socket.io');
const io = new Server(server);

app.use(koaStatic(path.resolve(__dirname, './public')));

server.listen(35602, () => console.log("Server is listening on 35602"));
io.on("connection", socket => {
    socket.on("joinRoom", d => socket.join(d));
    console.log(`One New Client Joined! Now We have ${io.sockets.adapter.rooms.size} Members in this channel`); //This maybe have bug 'cause I don't know how to get room numbers using socket.io
    socket.on("pushMessage", d => socket.broadcast.emit("subscribe", d));
});