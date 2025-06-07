require('dotenv').config();
const express = require("express");
const { spawn, exec } = require("child_process");
const app = express();
app.use(express.json());
const commandToRun = "cd ~ && bash serv00keep.sh";
function runCustomCommand() {
    exec(commandToRun, (err, stdout, stderr) => {
        if (err) console.error("执行错误:", err);
        else console.log("执行成功:", stdout);
    });
}
app.get("/up", (req, res) => {
    runCustomCommand();
    res.type("html").send("<pre>Serv00-name服务器网页保活启动：Serv00-name！UP！UP！UP！</pre>");
});
app.get("/re", (req, res) => {
    const additionalCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        FULL_PATH="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs"
        cd "\$FULL_PATH"
        pkill -f 'run -c con' || echo "无进程可终止，准备执行重启……"
        sbb="\$(cat sb.txt 2>/dev/null)"
        nohup ./"\$sbb" run -c config.json >/dev/null 2>&1 &
        sleep 2
        (cd ~ && bash serv00keep.sh >/dev/null 2>&1) &  
        echo '主程序重启成功，请检测三个主节点是否可用，如不可用，可再次刷新重启网页或者重置端口'
    `;
    exec(additionalCommands, (err, stdout, stderr) => {
        console.log('stdout:', stdout);
        console.error('stderr:', stderr);
        if (err) {
            return res.status(500).send(`错误：${stderr || stdout}`);
        }
        res.type('text').send(stdout);
    });
}); 

const changeportCommands = "cd ~ && bash webport.sh"; 
function runportCommand() {
exec(changeportCommands, { maxBuffer: 1024 * 1024 * 10 }, (err, stdout, stderr) => {
        console.log('stdout:', stdout);
        console.error('stderr:', stderr);
        if (err) {
            console.error('Execution error:', err);
            return res.status(500).send(`错误：${stderr || stdout}`);
        }
        if (stderr) {
            console.error('stderr output:', stderr);
            return res.status(500).send(`stderr: ${stderr}`);
        }
        res.type('text').send(stdout);
    });
}
app.get("/rp", (req, res) => {
   runportCommand();  
   res.type("html").send("<pre>重置三个节点端口完成！请立即关闭本网页并稍等20秒，将主页后缀改为  /list/你的uuid  可查看更新端口后的节点及订阅信息</pre>");
});
app.get("/list/key", (req, res) => {
    const listCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        USERNAME1=$(whoami)
        FULL_PATH="/home/\${USERNAME1}/domains/\${USERNAME}.serv00.net/logs/list.txt"
        cat "\$FULL_PATH"
    `;
    exec(listCommands, (err, stdout, stderr) => {
        if (err) {
            console.error(`路径验证失败: ${stderr}`);
            return res.status(404).send(stderr);
        }
        res.type('text').send(stdout);
    });
});

app.get("/jc", (req, res) => {
    const ps = spawn("ps", ["aux"]);
    res.type("text");
    ps.stdout.on("data", (data) => res.write(data));
    ps.stderr.on("data", (data) => res.write(`Error: ${data}`));
    ps.on("close", (code) => {
        if (code !== 0) {
            res.status(500).send(`ps aux 进程退出，错误码: ${code}`);
        } else {
            res.end();
        }
    });
});

app.use((req, res) => {
    res.status(404).send('请在浏览器地址：http://where.name.serv00.net 后面加三种路径功能：/up是保活，/re是重启，/rp是重置节点端口，/jc是查看当前系统进程，/list/你的uuid 是节点及订阅信息');
});
setInterval(runCustomCommand, (2 * 60 + 15) * 60 * 1000);
app.listen(3000, () => {
    console.log("服务器运行在端口 3000");
    runCustomCommand();
});
