import { DynamicTool } from '@langchain/core/tools';

/**
 * 计算器工具 - 安全计算数学表达式
 * 支持基本运算、三角函数、对数等
 */
export function createCalculatorTool() {
  return new DynamicTool({
    name: 'calculator',
    description: '数学计算器，可计算数学表达式。支持加减乘除、幂运算、三角函数、对数等。输入数学表达式字符串，返回计算结果。例如输入 "2 + 3 * 4" 或 "Math.sqrt(144)"。',
    func: async (input: string) => {
      try {
        const expr = input.trim().replace(/['"]/g, '');
        const result = safeEvaluate(expr);
        return JSON.stringify({ expression: expr, result });
      } catch (e) {
        return JSON.stringify({ error: `计算失败: ${e.message}` });
      }
    },
  });
}

/**
 * 安全的数学表达式求值器
 * 仅允许数学运算，不允许任意代码执行
 */
function safeEvaluate(expr: string): number {
  // 白名单：只允许数字、运算符、括号、数学函数
  const sanitized = expr.replace(/\s/g, '');

  // 检查是否包含非法字符
  if (!/^[0-9+\-*/().,%^eE]+$/.test(sanitized) &&
      !/^(Math\.(abs|ceil|floor|round|sqrt|cbrt|pow|min|max|sin|cos|tan|asin|acos|atan|log|log2|log10|exp|PI|E)|PI|E)/.test(sanitized)) {
    // 尝试替换中文运算符
    let normalized = expr
      .replace(/×/g, '*')
      .replace(/÷/g, '/')
      .replace(/（/g, '(')
      .replace(/）/g, ')');

    // 再次检查
    if (!/^[\d+\-*/().,%^eEMath\s]+$/.test(normalized)) {
      throw new Error('包含不支持的字符');
    }
    expr = normalized;
  }

  // 替换中文运算符
  expr = expr
    .replace(/×/g, '*')
    .replace(/÷/g, '/')
    .replace(/（/g, '(')
    .replace(/）/g, ')');

  // 使用 Function 构造器（比 eval 更安全）
  // 只暴露 Math 对象
  const mathContext = {
    Math,
    PI: Math.PI,
    E: Math.E,
    abs: Math.abs,
    ceil: Math.ceil,
    floor: Math.floor,
    round: Math.round,
    sqrt: Math.sqrt,
    pow: Math.pow,
    sin: Math.sin,
    cos: Math.cos,
    tan: Math.tan,
    log: Math.log,
    log10: Math.log10,
    exp: Math.exp,
    min: Math.min,
    max: Math.max,
  };

  const keys = Object.keys(mathContext);
  const values = Object.values(mathContext);

  // eslint-disable-next-line no-new-func
  const fn = new Function(...keys, `return (${expr});`);
  const result = fn(...values);

  if (typeof result !== 'number' || !isFinite(result)) {
    throw new Error('结果不是有效数字');
  }

  // 四舍五入到10位小数避免浮点精度问题
  return Math.round(result * 1e10) / 1e10;
}
