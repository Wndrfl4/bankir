const bcrypt = require('bcrypt');
const { PrismaClient, UserRole } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  const username = process.env.ADMIN_USERNAME || 'admin';
  const email = process.env.ADMIN_EMAIL || 'admin@bankir.local';
  const password = process.env.ADMIN_PASSWORD || 'Admin123!';

  const existingUser = await prisma.user.findFirst({
    where: {
      OR: [{ username }, { email }],
    },
  });

  if (existingUser) {
    console.log(`Admin already exists: ${existingUser.username} (${existingUser.id})`);
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const user = await prisma.user.create({
    data: {
      username,
      email,
      passwordHash,
      role: UserRole.ADMIN,
      accounts: {
        create: {
          iban: `KZ${Date.now()}${Math.floor(Math.random() * 1000)}`,
          balance: 0,
          isPrimary: true,
        },
      },
    },
  });

  console.log(`Created admin: ${user.username} (${user.id})`);
  console.log(`email=${email}`);
  console.log(`password=${password}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
