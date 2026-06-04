import { DynamicTool } from '@langchain/core/tools';
import { PrismaService } from '../../../../prisma/prisma.service';

export function createGetUserInfoTool(prisma: PrismaService) {
  return new DynamicTool({
    name: 'get_user_info',
    description: '获取用户公开信息。输入用户ID，返回用户的昵称、简介、粉丝数等公开信息。',
    func: async (input: string) => {
      try {
        const userId = input.trim().replace(/['"]/g, '');

        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: {
            id: true,
            nickname: true,
            username: true,
            bio: true,
            avatar: true,
            followerCount: true,
            followingCount: true,
            postCount: true,
          },
        });

        if (!user) {
          return JSON.stringify({ error: '用户不存在' });
        }

        return JSON.stringify({
          id: user.id,
          nickname: user.nickname,
          username: user.username,
          bio: user.bio,
          avatar: user.avatar,
          followerCount: user.followerCount,
          followingCount: user.followingCount,
          postCount: user.postCount,
        });
      } catch (e) {
        return JSON.stringify({ error: e.message });
      }
    },
  });
}
