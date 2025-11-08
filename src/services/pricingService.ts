import { RouteType, VipClass } from '../types/database';

interface PricingConfig {
  baseFare: number;
  perKmRate: number;
  perMinuteRate: number;
  minimumFare: number;
  multiplier: number;
}

// Configuration des tarifs par type de véhicule
const PRICING_CONFIG: Record<RouteType, PricingConfig> = {
  taxi: {
    baseFare: 500,
    perKmRate: 250,
    perMinuteRate: 50,
    minimumFare: 1000,
    multiplier: 1.0,
  },
  moto: {
    baseFare: 300,
    perKmRate: 150,
    perMinuteRate: 30,
    minimumFare: 500,
    multiplier: 1.0,
  },
  vip: {
    baseFare: 2000,
    perKmRate: 500,
    perMinuteRate: 100,
    minimumFare: 3000,
    multiplier: 1.0,
  },
  carpool: {
    baseFare: 400,
    perKmRate: 200,
    perMinuteRate: 40,
    minimumFare: 800,
    multiplier: 0.8,
  },
};

// Multiplicateurs pour les classes VIP
const VIP_MULTIPLIERS: Record<VipClass, number> = {
  business: 1.2,
  luxe: 1.5,
  xl: 1.8,
};

export class PricingService {
  /**
   * Calcule le tarif d'un trajet
   */
  static calculateFare(
    routeType: RouteType,
    distanceKm: number,
    durationMinutes: number,
    vipClass?: VipClass,
    trafficMultiplier: number = 1.0,
    weatherSurcharge: number = 0,
    waitingFee: number = 0
  ): {
    baseFare: number;
    distanceFare: number;
    timeFare: number;
    vipMultiplier: number;
    totalFare: number;
  } {
    const config = PRICING_CONFIG[routeType];
    let multiplier = config.multiplier;

    // Appliquer le multiplicateur VIP si applicable
    if (routeType === 'vip' && vipClass) {
      multiplier *= VIP_MULTIPLIERS[vipClass];
    }

    // Calcul des composantes du tarif
    const baseFare = config.baseFare * multiplier;
    const distanceFare = distanceKm * config.perKmRate * multiplier * trafficMultiplier;
    const timeFare = durationMinutes * config.perMinuteRate * multiplier;

    // Calcul du tarif total
    let totalFare = baseFare + distanceFare + timeFare + weatherSurcharge + waitingFee;

    // Appliquer le tarif minimum
    if (totalFare < config.minimumFare * multiplier) {
      totalFare = config.minimumFare * multiplier;
    }

    return {
      baseFare: Math.round(baseFare * 100) / 100,
      distanceFare: Math.round(distanceFare * 100) / 100,
      timeFare: Math.round(timeFare * 100) / 100,
      vipMultiplier: routeType === 'vip' && vipClass ? VIP_MULTIPLIERS[vipClass] : 1.0,
      totalFare: Math.round(totalFare * 100) / 100,
    };
  }

  /**
   * Estime la distance et la durée d'un trajet
   * Note: Dans une vraie application, utiliser une API comme Google Maps ou OSRM
   */
  static async estimateDistanceAndDuration(
    pickupLat: number,
    pickupLng: number,
    dropoffLat: number,
    dropoffLng: number
  ): Promise<{ distanceKm: number; durationMinutes: number }> {
    // Calcul simple de distance (Haversine)
    const R = 6371; // Rayon de la Terre en km
    const dLat = this.toRad(dropoffLat - pickupLat);
    const dLon = this.toRad(dropoffLng - pickupLng);
    const lat1 = this.toRad(pickupLat);
    const lat2 = this.toRad(dropoffLat);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = R * c;

    // Estimation de la durée (vitesse moyenne de 30 km/h en ville)
    const averageSpeedKmh = 30;
    const durationMinutes = (distanceKm / averageSpeedKmh) * 60;

    return {
      distanceKm: Math.round(distanceKm * 100) / 100,
      durationMinutes: Math.round(durationMinutes),
    };
  }

  private static toRad(degrees: number): number {
    return (degrees * Math.PI) / 180;
  }

  /**
   * Calcule la commission de la plateforme
   */
  static calculateCommission(totalFare: number, commissionRate: number = 15): number {
    return Math.round((totalFare * commissionRate) / 100 * 100) / 100;
  }
}

