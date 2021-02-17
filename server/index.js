const Koa = require('koa');
const koaStatic = require('koa-static');
const bodyParser = require('koa-bodyparser');
const path = require('path');
const {PORT, TOKEN} = require('./config.json');
const app = new Koa();
const server = require('http').createServer(app.callback());
const {Server} = require('socket.io');
const io = new Server(server);
app.use(bodyParser());
app.use(koaStatic(path.resolve(__dirname, './public')));
app.use(async (ctx, next) => {
    if (ctx.request.path === '/auth') {
        console.log(ctx.request.body);
        const token = new URL(ctx.request.body).searchParams.get('token');
        ctx.status = token === TOKEN ? 200 : 401;
        await next();
    }
});//auth router
server.listen(PORT, () => console.log(`http://localhost:${PORT}`));
io.on("connection", socket => {
    socket.on("joinRoom", d => socket.join(d));
    console.log(`One New Client Joined! Now We have ${io.sockets.adapter.rooms.size} Members in this channel`); //This maybe have bug 'cause I don't know how to get room numbers using socket.io
    socket.on("pushMessage", d => socket.broadcast.emit("subscribe", d));
});
