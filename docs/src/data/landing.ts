import { ar } from './landing-ar';
import { cs } from './landing-cs';
import { de } from './landing-de';
import { el } from './landing-el';
import { en } from './landing-en';
import { enGb } from './landing-en-GB';
import { es } from './landing-es';
import { esMx } from './landing-es-MX';
import { fa } from './landing-fa';
import { fr } from './landing-fr';
import { frCa } from './landing-fr-CA';
import { he } from './landing-he';
import { hu } from './landing-hu';
import { id } from './landing-id';
import { it } from './landing-it';
import { ja } from './landing-ja';
import { ko } from './landing-ko';
import { ms } from './landing-ms';
import { nb } from './landing-nb';
import { nl } from './landing-nl';
import { pl } from './landing-pl';
import { pt } from './landing-pt';
import { ptPt } from './landing-pt-PT';
import { ro } from './landing-ro';
import { ru } from './landing-ru';
import { sv } from './landing-sv';
import { th } from './landing-th';
import { tr } from './landing-tr';
import { uk } from './landing-uk';
import { ur } from './landing-ur';
import { vi } from './landing-vi';
import { zh } from './landing-zh';
import { zhHk } from './landing-zh-HK';
import { zhTw } from './landing-zh-TW';
import type { LandingCopy } from './landing-en';
import type { SiteLocale } from './locales';

export type { LandingCopy };

export const landingCopy: Record<SiteLocale, LandingCopy> = {
  'ar-SA': ar,
  'cs-CZ': cs,
  'de-DE': de,
  'el-GR': el,
  'en-GB': enGb,
  'en-US': en,
  'es-ES': es,
  'es-MX': esMx,
  'fa-IR': fa,
  'fr-CA': frCa,
  'fr-FR': fr,
  'he-IL': he,
  'hu-HU': hu,
  'id-ID': id,
  'it-IT': it,
  'ja-JP': ja,
  'ko-KR': ko,
  'ms-MY': ms,
  'nb-NO': nb,
  'nl-NL': nl,
  'pl-PL': pl,
  'pt-BR': pt,
  'pt-PT': ptPt,
  'ro-RO': ro,
  'ru-RU': ru,
  'sv-SE': sv,
  'th-TH': th,
  'tr-TR': tr,
  'uk-UA': uk,
  'ur-PK': ur,
  'vi-VN': vi,
  'zh-CN': zh,
  'zh-HK': zhHk,
  'zh-TW': zhTw,
};

