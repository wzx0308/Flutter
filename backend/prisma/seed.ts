import { PrismaClient, User } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // 创建管理员账号
  const adminPassword = await bcrypt.hash('Admin123456', 10);
  const admin = await prisma.user.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      username: 'admin',
      nickname: '管理员',
      password: adminPassword,
      role: 'ADMIN',
      bio: '系统管理员',
    },
  });
  console.log(`✅ Admin user: ${admin.username} (id: ${admin.id})`);

  // 创建测试用户
  const testPassword = await bcrypt.hash('Test123456', 10);
  const users: User[] = [];
  for (let i = 1; i <= 5; i++) {
    const user = await prisma.user.upsert({
      where: { username: `user${i}` },
      update: {},
      create: {
        username: `user${i}`,
        nickname: `测试用户${i}`,
        password: testPassword,
        bio: `这是测试用户${i}的个人简介`,
        followerCount: 0,
        followingCount: 0,
      },
    });
    users.push(user);
    console.log(`✅ Test user: ${user.username}`);
  }

  // 创建测试帖子
  const posts = [
    { content: '今天天气真好，适合出去走走！#生活 #日常', tags: ['生活', '日常'], authorId: users[0].id },
    { content: '分享一个Flutter开发小技巧：使用GetBuilder可以更精细地控制状态刷新。', tags: ['Flutter', '开发'], authorId: users[1].id },
    { content: '刚完成了一个社交App的MVP，欢迎大家体验！', tags: ['社交', 'App'], authorId: users[2].id },
    { content: 'NestJS + Prisma + PostgreSQL 真是后端开发的黄金组合。', tags: ['NestJS', 'Prisma', 'PostgreSQL'], authorId: users[3].id },
    { content: '学习Socket.IO实时通讯的心得：WebSocket连接管理和断线重连是关键。', tags: ['Socket.IO', 'IM'], authorId: users[4].id },
    { title: 'Flutter状态管理方案对比', content: '本文对比了GetX、Provider、Riverpod、Bloc四种主流状态管理方案的优缺点，帮助开发者选择最适合自己项目的方案。', type: 'ARTICLE', tags: ['Flutter', '状态管理'], authorId: users[0].id },
    { content: '周末去爬山了，风景很美！🏔️', tags: ['爬山', '周末'], authorId: users[1].id, locationName: '香山公园', latitude: 39.9907, longitude: 116.1865 },
  ];

  for (const postData of posts) {
    const post = await prisma.post.create({ data: postData as any });
    console.log(`✅ Post created: ${post.id}`);
  }

  // 创建关注关系
  await prisma.follow.createMany({
    data: [
      { followerId: users[0].id, followingId: users[1].id },
      { followerId: users[0].id, followingId: users[2].id },
      { followerId: users[1].id, followingId: users[0].id },
      { followerId: users[2].id, followingId: users[0].id },
      { followerId: users[3].id, followingId: users[4].id },
    ],
    skipDuplicates: true,
  });

  // 更新关注计数
  for (const user of users) {
    const followerCount = await prisma.follow.count({ where: { followingId: user.id } });
    const followingCount = await prisma.follow.count({ where: { followerId: user.id } });
    await prisma.user.update({ where: { id: user.id }, data: { followerCount, followingCount } });
  }
  console.log('✅ Follow relationships created');

  // 创建私聊会话
  const conversation = await prisma.conversation.create({
    data: {
      type: 'PRIVATE',
      members: {
        create: [
          { userId: users[0].id, role: 'OWNER' },
          { userId: users[1].id, role: 'MEMBER' },
        ],
      },
    },
  });

  await prisma.message.createMany({
    data: [
      { conversationId: conversation.id, senderId: users[0].id, content: '你好！', type: 'TEXT' },
      { conversationId: conversation.id, senderId: users[1].id, content: '你好，有什么事吗？', type: 'TEXT' },
      { conversationId: conversation.id, senderId: users[0].id, content: '想请教一个Flutter的问题', type: 'TEXT' },
    ],
  });
  console.log('✅ Conversation and messages created');

  console.log('🎉 Seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
