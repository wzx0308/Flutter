import { DynamicTool } from '@langchain/core/tools';
import axios from 'axios';

/**
 * 天气查询工具 - 使用 wttr.in 免费 API
 * 无需 API Key
 */
export function createWeatherTool() {
  return new DynamicTool({
    name: 'get_weather',
    description: '天气查询工具，可查询指定城市的当前天气和未来预报。输入城市名称（如"北京"、"上海"），返回天气信息。',
    func: async (input: string) => {
      try {
        const city = input.trim().replace(/['"]/g, '');
        const weather = await fetchWeather(city);
        return JSON.stringify(weather);
      } catch (e) {
        return JSON.stringify({ error: `天气查询失败: ${e.message}` });
      }
    },
  });
}

async function fetchWeather(city: string) {
  // 使用 wttr.in 获取天气（JSON 格式）
  const response = await axios.get(`https://wttr.in/${encodeURIComponent(city)}?format=j1`, {
    timeout: 10000,
    headers: {
      'User-Agent': 'curl/7.64.1',
      'Accept-Language': 'zh-CN,zh;q=0.9',
    },
  });

  const data = response.data;
  const current = data.current_condition?.[0];
  const today = data.weather?.[0];

  if (!current) {
    throw new Error('无法获取天气数据');
  }

  return {
    city,
    temperature: `${current.temp_C}°C`,
    feelsLike: `${current.FeelsLikeC}°C`,
    description: current.lang_zh?.[0]?.value || current.weatherDesc?.[0]?.value || '未知',
    humidity: `${current.humidity}%`,
    windSpeed: `${current.windspeedKmph} km/h`,
    windDirection: current.winddir16Point,
    visibility: `${current.visibility} km`,
    uvIndex: current.uvIndex,
    todayHigh: today ? `${today.maxtempC}°C` : '未知',
    todayLow: today ? `${today.mintempC}°C` : '未知',
    sunrise: today?.astronomy?.[0]?.sunrise || '未知',
    sunset: today?.astronomy?.[0]?.sunset || '未知',
  };
}
