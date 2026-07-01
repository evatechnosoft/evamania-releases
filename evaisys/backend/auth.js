// EvaISYS — kimlik doğrulama: JWT (kullanıcı) + cihaz token (ESP32).
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { findUser, deviceByToken } from './store.js';

const JWT_SECRET = process.env.JWT_SECRET || 'evaisys-dev-secret-change-me';
const JWT_TTL = process.env.JWT_TTL || '12h';

/** Kullanıcı adı/parola doğrula, JWT döndür (yoksa null). */
export function login(username, password) {
  const user = findUser(username);
  if (!user) return null;
  if (!bcrypt.compareSync(password, user.password_hash)) return null;
  const token = jwt.sign({ sub: user.username, role: user.role }, JWT_SECRET, { expiresIn: JWT_TTL });
  return { token, user: { username: user.username, role: user.role } };
}

/** Express middleware — geçerli kullanıcı JWT'si ister (Authorization: Bearer). */
export function requireUser(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ ok: false, error: 'token gerekli' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ ok: false, error: 'geçersiz/expired token' });
  }
}

/** JWT'yi doğrudan doğrula (WebSocket el sıkışması için). */
export function verifyUserToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch {
    return null;
  }
}

/** Express middleware — geçerli cihaz token'ı ister (X-Device-Token).
 *  Token'ın ait olduğu vehicleId'yi req.deviceVehicleId'ye koyar. */
export function requireDevice(req, res, next) {
  const token = req.headers['x-device-token'];
  if (!token) return res.status(401).json({ ok: false, error: 'cihaz token gerekli' });
  const device = deviceByToken(token);
  if (!device) return res.status(401).json({ ok: false, error: 'geçersiz cihaz token' });
  req.deviceVehicleId = device.vehicle_id;
  next();
}
