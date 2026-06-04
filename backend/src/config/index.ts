export default () => ({
  port: parseInt(process.env.APP_PORT || '3000', 10),
  database: {
    url: process.env.DATABASE_URL,
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://:redis123@localhost:6379',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret',
    accessExpires: process.env.JWT_ACCESS_EXPIRES || '2h',
    refreshExpires: process.env.JWT_REFRESH_EXPIRES || '7d',
  },
  agora: {
    appId: process.env.AGORA_APP_ID || '',
    appCertificate: process.env.AGORA_APP_CERTIFICATE || '',
  },
  alipay: {
    appId: process.env.ALIPAY_APP_ID || '',
    gateway: process.env.ALIPAY_GATEWAY || 'https://openapi-sandbox.dl.alipaydev.com/gateway.do',
    notifyUrl: process.env.ALIPAY_NOTIFY_URL || '',
    appPublicKey: process.env.ALIPAY_APP_PUBLIC_KEY || '',
    publicKey: process.env.ALIPAY_PUBLIC_KEY || '',
    privateKey: process.env.ALIPAY_PRIVATE_KEY || '',
    signType: (process.env.ALIPAY_SIGN_TYPE as 'RSA' | 'RSA2') || 'RSA2',
  },
});
