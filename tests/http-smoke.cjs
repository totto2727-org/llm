const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const { once } = require('node:events');
const { createServer } = require('node:http');

const openai = (content, finish = null) => JSON.stringify({
  choices: [{ index: 0, delta: { content }, finish_reason: finish }],
});

async function main() {
  let pending;
  const server = createServer(async (request, response) => {
    try {
      if (request.url === '/continue') {
        const tail = Buffer.from(`data: ${openai('日本語')}\n\ndata: ${openai('', 'stop')}\n\ndata: [DONE]\n\ndata: ${openai('ignored')}\n\n`);
        const split = tail.indexOf(Buffer.from('日')) + 1;
        pending.write(tail.subarray(0, split));
        pending.write(tail.subarray(split));
        pending = undefined;
        response.writeHead(204).end();
        return;
      }
      const chunks = [];
      for await (const chunk of request) chunks.push(chunk);
      const body = JSON.parse(Buffer.concat(chunks).toString());
      if (request.url === '/failure') {
        response.writeHead(503).end('unavailable');
        return;
      }
      response.writeHead(200, { 'Content-Type': 'text/event-stream' });
      response.flushHeaders();
      switch (request.url) {
        case '/v1/chat/completions':
          assert.equal(request.headers.authorization, 'Bearer test');
          assert.equal(body.messages[0].content, '日本語');
          assert.equal(body.stream, true);
          pending = response;
          response.write(': heartbeat\r\nevent: message\r\ndata: {\r\ndata: ' + openai('first').slice(1) + '\r\n\r\n');
          break;
        case '/v1/messages':
          assert.equal(request.headers['x-api-key'], 'test');
          assert.equal(body.stream, true);
          response.end('data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"anthropic"}}\n\n' +
            'data: {"type":"message_stop"}\n\n');
          break;
        case '/cancel':
          response.write('data: started\n\n');
          break;
        case '/timeout':
          break;
        default:
          throw new Error(`Unexpected path ${request.url}`);
      }
    } catch (error) {
      console.error(error);
      response.destroy(error);
      process.exitCode = 1;
    }
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    const targets = process.argv.slice(2);
    for (const target of targets.length ? targets : ['js', 'native', 'wasm']) {
      const child = spawn('moon', ['run', 'src/test/http', '--target', target], {
        env: { ...process.env, LLM_TEST_URL: `http://127.0.0.1:${server.address().port}` },
        stdio: ['ignore', 'pipe', 'inherit'],
        signal: AbortSignal.timeout(120_000),
      });
      let output = '';
      child.stdout.setEncoding('utf8').on('data', (chunk) => { output += chunk; });
      const [code] = await once(child, 'close');
      assert.equal(code, 0, `${target}: ${output}`);
      assert.match(output, /HTTP_SSE_OK/, target);
      console.log(`${target}: HTTP_SSE_OK`);
    }
  } finally {
    server.closeAllConnections();
    server.close();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
