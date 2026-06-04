import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
  Res,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Logger,
  HttpCode,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import * as fs from 'fs';
import axios from 'axios';
import { LangchainService } from './langchain/langchain.service';
import { PromptTemplateService } from './langchain/prompt-template.service';
import { RagService } from './langchain/rag.service';
import { TextExtractionService } from './langchain/text-extraction.service';
import { PrismaService } from '../../prisma/prisma.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { KNOWLEDGE_BASE } from './langchain/seed-knowledge';

const ANYOU_SYSTEM_PROMPT = `【身份定位】
你是「安隅」社交APP专属智能小助手，扎根安隅产品生态，只作为平台内置AI助手服务安隅注册用户，没有独立身份，不冒充真人用户。
产品简介：安隅是生活化同城社交软件，主打陌生人/好友闲聊、动态发布、同城交友、线上互动。

【核心工作规则】
1. 业务答疑能力
① 用户询问APP功能：动态发布、私信聊天、音视频通话、同城筛选、充值会员、账单问题、账号设置、隐私权限、黑名单、发布规范，精准依据安隅产品规则解答；不清楚的功能统一回复：「该功能细节可查看APP-我的-帮助中心」。
② 无法处理充值退款、账号封禁申诉：引导用户联系平台人工客服。

2. 社交陪伴能力
① 用户闲聊、倾诉情绪、日常吐槽、交友困惑、恋爱烦恼、生活琐事，温柔共情回复，语气轻松温暖，贴合社交软件陪伴属性；
② 用户想要找同城好友、搭子聊天：引导使用安隅首页同城板块，不私自留下联系方式、微信、QQ、外部链接。

3. 动态辅助创作
用户需要发布朋友圈/动态文案：根据用户给的心情、场景（吃饭、出游、独处、伤感、日常）生成适配安隅风格短句，文案简短生活化，可选多版本。

4. 内容风控红线（硬性约束，严格执行）
① 拒绝色情、低俗、赌博、网贷、兼职刷单、引流外链、政治敏感、违法违规相关提问；遇到直接委婉拒绝：「很抱歉，我不能解答该问题哦，我们聊聊日常吧」；
② 不编造安隅不存在的功能、收费规则、活动福利；
③ 不诱导用户线下私自交易、转账、私下见面。

【输出格式规范（严格遵守）】
① 纯文本输出，禁止使用任何Markdown格式符号，包括但不限于：加粗、标题、列表、代码块、引用、链接等；
② emoji少量点缀即可，每次回复最多1～2个，禁止堆砌emoji；
③ 回复用自然口语化的段落，不要用序号列表堆砌；
④ 如果需要列举多项内容，用逗号或顿号分隔，写成自然语句。

【对话风格规范】
1. 语气：温柔亲切、短句为主，不用生硬机器话术，口语化，适当温和，不高冷；
2. 篇幅：普通闲聊1～3行，文案需求按需长短，不输出大段冗余文字；
3. 称呼：用户无昵称统一用小伙伴，记住用户历史聊天偏好（依托上下文记忆）；
4. 禁止：跳出安隅身份聊无关专业科普、编程、跨平台产品介绍。

【附加RAG规则（对接知识库生效）】
当用户询问安隅专属活动、新版本更新、会员权益、平台新规时，优先读取知识库内容作答，知识库无记录则引导帮助中心。`;

@ApiTags('AI代理')
@ApiBearerAuth()
@Controller('ai-proxy')
export class AiProxyController {
  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly logger = new Logger(AiProxyController.name);

  constructor(
    private config: ConfigService,
    private langchainService: LangchainService,
    private promptTemplateService: PromptTemplateService,
    private ragService: RagService,
    private textExtractionService: TextExtractionService,
    private prisma: PrismaService,
  ) {
    this.apiKey = this.config.get<string>('AI_API_KEY') || '';
    this.baseUrl = this.config.get<string>('AI_BASE_URL') || 'https://api.xiaomimimo.com/v1';
    this.logger.log(`AI Proxy initialized: baseUrl=${this.baseUrl}`);
  }

  // ════════════════════════════════════════
  //  AI 对话（支持 standard / rag / agent 模式）
  // ════════════════════════════════════════

  @Post('chat/completions')
  @ApiOperation({ summary: 'AI对话（支持 standard/rag/agent 模式）' })
  async chatCompletions(@Body() body: any, @CurrentUser('id') userId?: string) {
    const mode = body.mode || 'standard';
    const conversationId = body.conversationId;

    // 标准模式：直接代理（向后兼容）
    if (mode === 'standard') {
      return this.proxyChat(body);
    }

    const messages = body.messages || [];
    this.logger.log(`Chat request: mode=${mode}, model=${body.model}, messages=${messages.length}`);

    // LangChain 模式
    try {
      let reply: string;

      switch (mode) {
        case 'rag':
          reply = await this.langchainService.ragChat(messages, { userId, conversationId });
          break;
        case 'agent':
          reply = await this.langchainService.agentChat(messages, { userId, conversationId });
          break;
        default:
          reply = await this.langchainService.standardChat(messages, { userId, conversationId });
      }

      return {
        choices: [{ message: { content: reply, role: 'assistant' } }],
        usage: { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 },
      };
    } catch (error) {
      this.logger.error(`LangChain error: ${error.message}`);
      throw new BadRequestException(error.message || 'AI请求失败');
    }
  }

  /**
   * 标准模式代理（保持原有行为）
   */
  private async proxyChat(body: any) {
    const messages = body.messages || [];
    if (messages.length === 0 || messages[0]?.role !== 'system') {
      messages.unshift({
        role: 'system',
        content: ANYOU_SYSTEM_PROMPT,
      });
    }

    this.logger.log(`proxyChat: model=${body.model}, messages=${messages.length}, baseUrl=${this.baseUrl}`);

    try {
      const response = await axios.post(`${this.baseUrl}/chat/completions`, {
        model: body.model || 'mimo-v2.5',
        messages,
        stream: false,
      }, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 120000,
      });

      this.logger.log(`Chat response: status=${response.status}, choices=${response.data?.choices?.length}`);
      return response.data;
    } catch (error) {
      this.logger.error(`Chat error: ${error.response?.status} ${JSON.stringify(error.response?.data)?.substring(0, 300) || error.message}`);
      const message = error.response?.data?.error?.message || error.message || 'AI请求失败';
      throw new BadRequestException(message);
    }
  }

  @Post('chat/completions/stream')
  @HttpCode(200)
  @ApiOperation({ summary: 'AI对话流式SSE（支持standard/rag/agent模式）' })
  async chatCompletionsStream(@Body() body: any, @Req() req: Request, @Res() res: Response, @CurrentUser('id') userId?: string) {
    const mode = body.mode || 'standard';
    const conversationId = body.conversationId;

    // 设置 SSE 响应头
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no');

    // 标准模式：直接代理转发
    if (mode === 'standard') {
      try {
        // 注入系统提示词
        const messages = body.messages || [];
        if (messages.length === 0 || messages[0]?.role !== 'system') {
          messages.unshift({ role: 'system', content: ANYOU_SYSTEM_PROMPT });
        }

        const response = await axios.post(`${this.baseUrl}/chat/completions`, {
          model: body.model || 'mimo-v2.5',
          messages,
          stream: true,
        }, {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 300000,
          responseType: 'stream',
        });

        // 直接管道转发
        response.data.on('error', (err) => {
          this.logger.error(`Stream pipe error: ${err.message}`);
          try { res.end(); } catch (_) {}
        });
        response.data.pipe(res);
        return;
      } catch (error) {
        this.logger.error(`Stream proxy error: ${error.message}`);
        const errData = JSON.stringify({ choices: [{ delta: { content: `请求失败: ${error.message}` } }] });
        res.write(`data: ${errData}\n\n`);
        res.write('data: [DONE]\n\n');
        res.end();
        return;
      }
    }

    // LangChain 流式模式（RAG/Agent）
    try {
      const messages = body.messages || [];
      const stream = this.langchainService.standardChatStream(messages, { userId, conversationId });

      for await (const chunk of stream) {
        const data = JSON.stringify({ choices: [{ delta: { content: chunk } }] });
        res.write(`data: ${data}\n\n`);
      }
      res.write('data: [DONE]\n\n');
      res.end();
    } catch (error) {
      this.logger.error(`LangChain stream error: ${error.message}`);
      try {
        res.write(`data: ${JSON.stringify({ choices: [{ delta: { content: `请求失败: ${error.message}` } }] })}\n\n`);
        res.write('data: [DONE]\n\n');
        res.end();
      } catch (_) {
        res.end();
      }
    }
  }

  // ════════════════════════════════════════
  //  Prompt 模板管理
  // ════════════════════════════════════════

  @Get('prompt-templates')
  @ApiOperation({ summary: '获取所有 Prompt 模板' })
  async getPromptTemplates() {
    return this.promptTemplateService.getAll();
  }

  @Post('prompt-templates')
  @ApiOperation({ summary: '创建 Prompt 模板' })
  async createPromptTemplate(@Body() body: { name: string; systemPrompt: string; fewShotExamples?: any[] }) {
    return this.promptTemplateService.create(body.name, body.systemPrompt, body.fewShotExamples);
  }

  @Patch('prompt-templates/:id')
  @ApiOperation({ summary: '更新 Prompt 模板' })
  async updatePromptTemplate(@Param('id') id: string, @Body() body: any) {
    return this.promptTemplateService.update(id, body);
  }

  @Delete('prompt-templates/:id')
  @ApiOperation({ summary: '删除 Prompt 模板' })
  async deletePromptTemplate(@Param('id') id: string) {
    return this.promptTemplateService.delete(id);
  }

  // ════════════════════════════════════════
  //  RAG 索引管理
  // ════════════════════════════════════════

  @Post('rag/index')
  @ApiOperation({ summary: '索引帖子到 RAG 知识库' })
  async indexPosts(@Body() body: { postIds?: string[] }) {
    return this.ragService.indexPosts(body.postIds);
  }

  @Get('rag/stats')
  @ApiOperation({ summary: '获取 RAG 索引统计' })
  async getRagStats() {
    return this.ragService.getStats();
  }

  // ════════════════════════════════════════
  //  初始化默认 Prompt 模板
  // ════════════════════════════════════════

  @Post('init-prompt')
  @Public()
  @ApiOperation({ summary: '初始化安隅AI默认提示词模板（仅首次需要）' })
  async initDefaultPrompt() {
    const existing = await this.promptTemplateService.getActive();
    if (existing) {
      return { message: '默认模板已存在', id: existing.id };
    }
    const template = await this.promptTemplateService.create(
      '安隅AI助手',
      ANYOU_SYSTEM_PROMPT,
      [
        { input: '你是谁', output: '我是安隅的AI小助手～有什么可以帮你的吗？' },
        { input: '安隅是什么', output: '安隅是一款生活化同城社交软件，可以发动态、聊天、找同城好友，欢迎多多使用呀～' },
      ],
    );
    return { message: '默认模板创建成功', id: template.id };
  }

  @Post('seed-knowledge')
  @Public()
  @ApiOperation({ summary: '导入安隅知识库到RAG（产品文档+会员规则+平台活动）' })
  async seedKnowledge() {
    let totalChunks = 0;
    for (const doc of KNOWLEDGE_BASE) {
      const count = await this.ragService.indexDocument(
        doc.sourceType,
        doc.sourceId,
        `${doc.title}\n\n${doc.content}`,
        { title: doc.title },
      );
      totalChunks += count;
    }
    return { message: '知识库导入完成', documents: KNOWLEDGE_BASE.length, chunks: totalChunks };
  }

  // ════════════════════════════════════════
  //  语音转文字（mimo-v2.5-asr via chat/completions）
  // ════════════════════════════════════════

  @Post('audio/transcriptions')
  @ApiOperation({ summary: '语音转文字（mimo ASR，解决CORS）' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads'),
        filename: (_req, file, cb) => {
          const uniqueName = `${randomUUID()}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }),
      limits: { fileSize: 25 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/^audio\/(mpeg|mp4|m4a|aac|wav|ogg|webm|x-m4a)$/)) {
          return cb(new BadRequestException('仅支持音频格式'), false);
        }
        cb(null, true);
      },
    }),
  )
  async transcribeAudio(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('请选择音频文件');
    }

    const filePath = join(process.cwd(), 'uploads', file.filename);

    try {
      const fileBuffer = fs.readFileSync(filePath);
      const base64Audio = fileBuffer.toString('base64');

      // mimo ASR API: 通过 chat/completions + input_audio 格式
      // 仅支持 wav/mp3 格式，m4a 需转为 wav
      let audioBase64 = base64Audio;
      let audioMimeType = file.mimetype;

      if (file.mimetype.includes('m4a') || file.mimetype.includes('mp4') || file.mimetype.includes('aac') || file.mimetype.includes('webm') || file.mimetype.includes('ogg')) {
        // m4a/aac 格式需转为 wav
        const wavBuffer = await this.convertToWav(filePath);
        audioBase64 = wavBuffer.toString('base64');
        audioMimeType = 'audio/wav';
      }

      const response = await axios.post(`${this.baseUrl}/chat/completions`, {
        model: 'mimo-v2.5-asr',
        messages: [{
          role: 'user',
          content: [
            {
              type: 'input_audio',
              input_audio: {
                data: `data:${audioMimeType};base64,${audioBase64}`,
                format: audioMimeType.includes('wav') ? 'wav' : 'mp3',
              },
            },
          ],
        }],
      }, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      });

      // 清理临时文件
      try { fs.unlinkSync(filePath); } catch (_) {}

      const content = response.data?.choices?.[0]?.message?.content || '';
      return { text: content };
    } catch (error: any) {
      try { fs.unlinkSync(filePath); } catch (_) {}

      this.logger.error(`ASR error: ${error.response?.status} ${JSON.stringify(error.response?.data)?.substring(0, 300) || error.message}`);
      const message = error.response?.data?.error?.message || error.message || '语音识别失败';
      throw new BadRequestException(message);
    }
  }

  /**
   * 将音频文件转为 WAV 格式（使用 ffmpeg）
   */
  private async convertToWav(inputPath: string): Promise<Buffer> {
    const { execSync } = require('child_process');
    const outputPath = inputPath.replace(/\.[^.]+$/, '.wav');

    // 查找可用的 ffmpeg 路径
    let ffmpegCmd = 'ffmpeg';
    const possiblePaths = [
      'ffmpeg',
      `${process.env.LOCALAPPDATA}\\Microsoft\\WinGet\\Links\\ffmpeg.exe`,
      'C:\\ffmpeg\\bin\\ffmpeg.exe',
      'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
      'C:\\ProgramData\\chocolatey\\bin\\ffmpeg.exe',
    ];

    for (const p of possiblePaths) {
      try {
        execSync(`"${p}" -version`, { timeout: 5000, stdio: 'pipe' });
        ffmpegCmd = p;
        break;
      } catch {}
    }

    try {
      execSync(`"${ffmpegCmd}" -y -i "${inputPath}" -ar 16000 -ac 1 -f wav "${outputPath}"`, {
        timeout: 15000,
        stdio: 'pipe',
      });
      const wavBuffer = fs.readFileSync(outputPath);
      try { fs.unlinkSync(outputPath); } catch (_) {}
      return wavBuffer;
    } catch {
      this.logger.warn('ffmpeg not available, sending original format');
      return fs.readFileSync(inputPath);
    }
  }

  // ════════════════════════════════════════
  //  RAG 文档管理
  // ════════════════════════════════════════

  @Post('rag/documents')
  @ApiOperation({ summary: '上传文档并索引到RAG知识库' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads'),
        filename: (_req, file, cb) => {
          const uniqueName = `${randomUUID()}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }),
      limits: { fileSize: 50 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        const allowed = [
          'application/pdf',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'text/plain',
          'text/markdown',
        ];
        if (!allowed.includes(file.mimetype)) {
          return cb(new BadRequestException('仅支持 PDF、DOCX、TXT、Markdown 格式'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadDocument(
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser('id') userId: string,
    @Body('conversationId') conversationId?: string,
  ) {
    if (!file) {
      throw new BadRequestException('请选择文件');
    }

    // 创建文档记录
    const ragDoc = await this.prisma.ragDocument.create({
      data: {
        userId,
        conversationId: conversationId || null,
        filename: file.filename,
        originalName: file.originalname,
        mimeType: file.mimetype,
        fileSize: file.size,
        status: 'processing',
      },
    });

    // 后台异步提取文本并索引
    const filePath = join(process.cwd(), 'uploads', file.filename);
    this.textExtractionService
      .extractText(filePath, file.mimetype)
      .then(async (text) => {
        if (!text || text.trim().length === 0) {
          await this.prisma.ragDocument.update({
            where: { id: ragDoc.id },
            data: { status: 'error', errorMessage: '文档内容为空' },
          });
          return;
        }
        const chunkCount = await this.ragService.indexDocument(
          'rag_document',
          ragDoc.id,
          text,
          { originalName: file.originalname, mimeType: file.mimetype },
        );
        await this.prisma.ragDocument.update({
          where: { id: ragDoc.id },
          data: { status: 'indexed', chunkCount },
        });
        this.logger.log(`文档索引完成: ${file.originalname}, ${chunkCount} 个块`);
      })
      .catch(async (e) => {
        this.logger.error(`文档索引失败: ${e.message}`);
        await this.prisma.ragDocument.update({
          where: { id: ragDoc.id },
          data: { status: 'error', errorMessage: e.message },
        });
      });

    return { code: 0, data: ragDoc };
  }

  @Get('rag/documents')
  @ApiOperation({ summary: '获取用户已上传的RAG文档列表' })
  async listDocuments(
    @CurrentUser('id') userId: string,
    @Query('conversationId') conversationId?: string,
  ) {
    const where: any = { userId };
    if (conversationId) {
      where.OR = [{ conversationId }, { conversationId: null }];
    }
    const docs = await this.prisma.ragDocument.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return { code: 0, data: docs };
  }

  @Delete('rag/documents/:id')
  @ApiOperation({ summary: '删除RAG文档及其向量块' })
  async deleteDocument(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    const doc = await this.prisma.ragDocument.findFirst({
      where: { id, userId },
    });
    if (!doc) {
      throw new BadRequestException('文档不存在');
    }

    // 删除向量块
    await this.ragService.deleteBySource('rag_document', id);
    // 删除文档记录
    await this.prisma.ragDocument.delete({ where: { id } });
    // 删除物理文件
    try {
      const filePath = join(process.cwd(), 'uploads', doc.filename);
      fs.unlinkSync(filePath);
    } catch (_) {}

    return { code: 0, message: '删除成功' };
  }
}
