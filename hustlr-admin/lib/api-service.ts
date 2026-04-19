import MockAdminDataService, {
  AdminAnalytics,
  FraudCase,
  AdminUser,
  SystemHealth,
  PayoutRequest,
  AdminPolicy,
} from './mock-data';
import { API_BASE } from './constants';

const BASE_URL = `${API_BASE}/api/admin`;

class AdminApiService {
  static useMockData = true;

  static setUseMockData(useMock: boolean) {
    AdminApiService.useMockData = useMock;
  }

  static async getAnalytics(): Promise<AdminAnalytics> {
    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 800));
      return MockAdminDataService.getAnalytics();
    }

    try {
      const response = await fetch(`${BASE_URL}/analytics`, {
        headers: { 'Content-Type': 'application/json' },
      });
      
      if (response.ok) {
        const data = await response.json();
        return data as AdminAnalytics;
      }
      throw new Error(`Failed to load analytics: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      throw e;
    }
  }

  static async getFraudQueue(options: {
    page?: number;
    limit?: number;
    status?: string;
  } = {}): Promise<FraudCase[]> {
    const { page = 1, limit = 20, status = 'FLAGGED' } = options;

    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 500));
      return MockAdminDataService.getFraudQueue(limit);
    }

    try {
      const response = await fetch(
        `${BASE_URL}/fraud-queue?page=${page}&limit=${limit}&status=${status}`,
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );

      if (response.ok) {
        const data = await response.json();
        return data.claims as FraudCase[];
      }
      throw new Error(`Failed to load fraud queue: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      throw e;
    }
  }

  static async getUsers(options: {
    page?: number;
    limit?: number;
    search?: string;
    tier?: string;
  } = {}): Promise<AdminUser[]> {
    const { page = 1, limit = 50, search, tier } = options;

    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 500));
      return MockAdminDataService.getUsers(limit);
    }

    try {
      let queryParams = `page=${page}&limit=${limit}`;
      if (search) queryParams += `&search=${search}`;
      if (tier) queryParams += `&tier=${tier}`;

      const response = await fetch(
        `${BASE_URL}/trust-scores?${queryParams}`,
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );

      if (response.ok) {
        const data = await response.json();
        return data.users as AdminUser[];
      }
      throw new Error(`Failed to load users: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      throw e;
    }
  }

  static async getSystemHealth(): Promise<SystemHealth> {
    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 300));
      return MockAdminDataService.getSystemHealth();
    }

    try {
      const response = await fetch(`${BASE_URL}/system-health`, {
        headers: { 'Content-Type': 'application/json' },
      });

      if (response.ok) {
        const data = await response.json();
        return data as SystemHealth;
      }
      throw new Error(`Failed to load system health: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      throw e;
    }
  }

  static async getPayoutQueue(options: {
    page?: number;
    limit?: number;
    status?: string;
  } = {}): Promise<PayoutRequest[]> {
    const { page = 1, limit = 20, status = 'APPROVED' } = options;

    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 500));
      return MockAdminDataService.getPayoutQueue(limit);
    }

    try {
      const response = await fetch(
        `${BASE_URL}/payout-queue?page=${page}&limit=${limit}&status=${status}`,
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );

      if (response.ok) {
        const data = await response.json();
        return data.payouts as PayoutRequest[];
      }
      throw new Error(`Failed to load payout queue: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      throw e;
    }
  }

  static async getPolicies(options: {
    page?: number;
    limit?: number;
    status?: string;
  } = {}): Promise<AdminPolicy[]> {
    const { page = 1, limit = 30, status } = options;

    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 500));
      return MockAdminDataService.getPolicies(limit);
    }

    try {
      let queryParams = `page=${page}&limit=${limit}`;
      if (status) queryParams += `&status=${status}`;

      const response = await fetch(
        `${BASE_URL}/policies?${queryParams}`,
        {
          headers: { 'Content-Type': 'application/json' },
        }
      );

      if (response.ok) {
        const data = await response.json();
        return data.policies as AdminPolicy[];
      }
      throw new Error(`Failed to load policies: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      throw e;
    }
  }

  static async updateFraudStatus(
    claimId: string,
    status: string,
    note?: string
  ): Promise<boolean> {
    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 300));
      return true;
    }

    try {
      const response = await fetch(`${BASE_URL}/fraud/${claimId}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, adminNote: note }),
      });

      return response.ok;
    } catch (e) {
      console.error('API Error:', e);
      return false;
    }
  }

  static async updateTrustScore(
    userId: string,
    score: number,
    reason?: string
  ): Promise<boolean> {
    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 300));
      return true;
    }

    try {
      const response = await fetch(`${BASE_URL}/trust/${userId}/score`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ score, reason }),
      });

      return response.ok;
    } catch (e) {
      console.error('API Error:', e);
      return false;
    }
  }

  static async processPayout(
    payoutId: string,
    paymentMethod: string,
    upiRef?: string
  ): Promise<boolean> {
    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 500));
      return true;
    }

    try {
      const response = await fetch(`${BASE_URL}/payout/${payoutId}/process`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ paymentMethod, upiRef }),
      });

      return response.ok;
    } catch (e) {
      console.error('API Error:', e);
      return false;
    }
  }

  static async runAdjudicator(): Promise<{
    success: boolean;
    claimsCreated?: number;
    durationMs?: number;
    error?: string;
  }> {
    if (AdminApiService.useMockData) {
      await new Promise(resolve => setTimeout(resolve, 2000));
      return {
        success: true,
        claimsCreated: Math.floor(Math.random() * 50) + 10,
        durationMs: Math.floor(Math.random() * 5000) + 1000,
      };
    }

    try {
      const response = await fetch(`${BASE_URL}/run-adjudicator`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (response.ok) {
        const data = await response.json();
        return data;
      }
      throw new Error(`Failed to run adjudicator: ${response.status}`);
    } catch (e) {
      console.error('API Error:', e);
      return {
        success: false,
        error: e instanceof Error ? e.message : 'Unknown error',
      };
    }
  }
}

export default AdminApiService;
