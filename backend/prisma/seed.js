const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Memulai proses seeding...');

  const passwordHash = await bcrypt.hash('123456', 10);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@toko.com' },
    update: {
      name: 'Super Admin',
      password: passwordHash,
      role: 'admin',
    },
    create: {
      email: 'admin@toko.com',
      name: 'Super Admin',
      password: passwordHash,
      role: 'admin',
    },
  });
  console.log(`✅ Akun Admin siap: ${admin.email}`);

  const staff = await prisma.user.upsert({
    where: { email: 'staff@toko.com' },
    update: {
      name: 'Kasir Staff',
      password: passwordHash,
      role: 'staff',
    },
    create: {
      email: 'staff@toko.com',
      name: 'Kasir Staff',
      password: passwordHash,
      role: 'staff',
    },
  });
  console.log(`✅ Akun Staff siap: ${staff.email}`);

  console.log('🚀 Seeding selesai!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });