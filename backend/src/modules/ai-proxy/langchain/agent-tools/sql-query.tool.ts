import { DynamicTool } from '@langchain/core/tools';
import { PrismaService } from '../../../../prisma/prisma.service';

/**
 * 数据库查询工具 - 只读 SQL 查询
 * 仅允许 SELECT 查询，禁止任何写操作
 */
export function createSqlQueryTool(prisma: PrismaService) {
  return new DynamicTool({
    name: 'sql_query',
    description: '数据库查询工具，可执行只读SQL查询获取平台数据。仅支持SELECT查询。适用于查询用户统计、帖子数据、活跃度等平台数据。',
    func: async (input: string) => {
      try {
        const query = input.trim().replace(/['"]/g, '');

        // 安全检查：只允许 SELECT 语句
        const normalized = query.toUpperCase().trim();
        if (!normalized.startsWith('SELECT')) {
          return JSON.stringify({ error: '仅支持 SELECT 查询，禁止写操作' });
        }

        // 禁止危险操作
        const forbidden = ['DROP', 'DELETE', 'UPDATE', 'INSERT', 'ALTER', 'TRUNCATE', 'EXEC', 'EXECUTE', 'UNION'];
        for (const kw of forbidden) {
          if (normalized.includes(kw)) {
            return JSON.stringify({ error: `禁止使用 ${kw} 操作` });
          }
        }

        // 限制查询结果数量（防止全表扫描）
        let safeQuery = query;
        if (!normalized.includes('LIMIT')) {
          safeQuery = `${query} LIMIT 20`;
        }

        const result = await prisma.$queryRawUnsafe(safeQuery);
        return JSON.stringify({ data: result, rowCount: Array.isArray(result) ? result.length : 0 });
      } catch (e) {
        return JSON.stringify({ error: `查询失败: ${e.message}` });
      }
    },
  });
}
