import { PrismaClient } from '@prisma/client';

import { loadConfig } from '../config.js';

const config = loadConfig();

if (config.dataStore !== 'prisma') {
  console.error(
    'DATA_STORE is not prisma. Set DATA_STORE=prisma in backend/.env before listing persistent users.',
  );
  process.exit(1);
}

const prisma = new PrismaClient();

try {
  const users = await prisma.user.findMany({
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      email: true,
      wechatOpenId: true,
      createdAt: true,
      updatedAt: true,
      _count: {
        select: {
          refreshSessions: true,
          tasks: true,
          summaries: true,
          quotas: true,
        },
      },
    },
  });

  if (users.length === 0) {
    console.log('No users found.');
  } else {
    console.table(
      users.map((user) => ({
        id: user.id,
        email: user.email ?? '',
        wechatBound: Boolean(user.wechatOpenId),
        tasks: user._count.tasks,
        summaries: user._count.summaries,
        quotas: user._count.quotas,
        refreshSessions: user._count.refreshSessions,
        createdAt: user.createdAt.toISOString(),
        updatedAt: user.updatedAt.toISOString(),
      })),
    );
  }
} catch (error) {
  console.error(
    'Could not read users. Make sure Postgres is running and DATABASE_URL points to the AIMemo database.',
  );
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
