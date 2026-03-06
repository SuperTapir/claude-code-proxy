#!/usr/bin/env node

import { spawn } from 'node:child_process';
import Enquirer from 'enquirer';
import { parseProxyModelsConf, getDefaultConfigPath } from './config-parser.js';
import { detectRunningProxies } from './process-detector.js';

/**
 * 连接到指定端口的代理
 * @param {number} port - 代理端口
 */
function connectToProxy(port) {
  const baseUrl = `http://127.0.0.1:${port}`;
  console.log(`连接到代理: ${baseUrl}\n`);
  spawn('claude', [], {
    stdio: 'inherit',
    env: { ...process.env, ANTHROPIC_BASE_URL: baseUrl },
  });
}

async function main() {
  // 解析配置
  const configPath = getDefaultConfigPath();
  const models = parseProxyModelsConf(configPath);
  if (models.length === 0) {
    console.log('未在 proxy_models.conf 中找到任何模型配置');
    process.exit(1);
  }

  // 检测运行中的代理
  console.log('正在检测运行中的代理...');
  const runningStatus = await detectRunningProxies(models);

  // 过滤出运行中的代理
  const runningModels = models.filter((m) => runningStatus.get(m.id));

  if (runningModels.length === 0) {
    console.log('没有检测到运行中的代理。');
    console.log('请先使用 ccc -auto -d -i 启动代理。');
    process.exit(1);
  }

  if (runningModels.length === 1) {
    // 只有一个运行中的代理，直接连接
    const model = runningModels[0];
    console.log(`检测到 1 个运行中的代理: ${model.description}\n`);
    connectToProxy(model.port);
    return;
  }

  // 多个运行中的代理，弹出单选菜单
  console.log(`检测到 ${runningModels.length} 个运行中的代理\n`);

  const { Select } = Enquirer;
  const prompt = new Select({
    name: 'proxy',
    message: '选择要连接的代理',
    choices: runningModels.map((model) => ({
      name: String(model.port),
      message: `${model.description}  (端口: ${model.port})`,
    })),
  });

  let selectedPort;
  try {
    selectedPort = await prompt.run();
  } catch {
    // 用户按 Ctrl+C 取消
    console.log('已取消');
    process.exit(0);
  }

  connectToProxy(parseInt(selectedPort, 10));
}

main().catch((err) => {
  console.error('错误:', err.message);
  process.exit(1);
});
