import { DynamicTool } from '@langchain/core/tools';
import axios from 'axios';

/**
 * 联网搜索工具 - 通过百度搜索获取实时信息
 * 无需 API Key，直接爬取百度搜索结果摘要
 */
export function createWebSearchTool() {
  return new DynamicTool({
    name: 'web_search',
    description: '联网搜索工具，可查询实时新闻、最新数据、百科知识等。输入搜索关键词，返回相关结果摘要。适用于用户询问最新事件、实时数据、百科知识等需要联网获取的信息。',
    func: async (input: string) => {
      try {
        const query = input.trim().replace(/['"]/g, '');
        const results = await searchBaidu(query);
        if (results.length === 0) {
          return JSON.stringify({ results: [], message: '未找到相关结果' });
        }
        return JSON.stringify({ results });
      } catch (e) {
        return JSON.stringify({ error: `搜索失败: ${e.message}` });
      }
    },
  });
}

async function searchBaidu(query: string): Promise<Array<{ title: string; snippet: string; url: string }>> {
  const url = `https://www.baidu.com/s`;
  const response = await axios.get(url, {
    params: { wd: query, rn: 5 },
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'zh-CN,zh;q=0.9',
    },
    timeout: 10000,
  });

  const html = response.data as string;
  const results: Array<{ title: string; snippet: string; url: string }> = [];

  // 解析百度搜索结果（简单正则提取）
  // 匹配标题和摘要
  const titleRegex = /<h3[^>]*>[\s\S]*?<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/g;
  const snippetRegex = /<span class="content-right_8Zs40">([\s\S]*?)<\/span>/g;

  let match;
  const titles: string[] = [];
  const urls: string[] = [];

  while ((match = titleRegex.exec(html)) !== null && titles.length < 5) {
    const title = match[2].replace(/<[^>]+>/g, '').trim();
    if (title) {
      titles.push(title);
      urls.push(match[1]);
    }
  }

  // 尝试匹配摘要
  const snippets: string[] = [];
  while ((match = snippetRegex.exec(html)) !== null && snippets.length < 5) {
    const snippet = match[1].replace(/<[^>]+>/g, '').trim();
    if (snippet) snippets.push(snippet);
  }

  // 如果正则匹配不够，尝试简单的文本提取
  if (titles.length === 0) {
    // 备用方案：提取所有文本块
    const textBlocks = html
      .replace(/<script[\s\S]*?<\/script>/gi, '')
      .replace(/<style[\s\S]*?<\/style>/gi, '')
      .replace(/<[^>]+>/g, '\n')
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 20 && line.length < 200 && /[一-龥]/.test(line));

    for (let i = 0; i < Math.min(5, textBlocks.length); i++) {
      results.push({
        title: textBlocks[i],
        snippet: textBlocks[i + 1] || '',
        url: '',
      });
    }
    return results;
  }

  for (let i = 0; i < titles.length; i++) {
    results.push({
      title: titles[i],
      snippet: snippets[i] || '',
      url: urls[i] || '',
    });
  }

  return results;
}
