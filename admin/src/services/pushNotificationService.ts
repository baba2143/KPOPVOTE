import { getAuth } from 'firebase/auth';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'https://us-central1-kpopvote-9de2b.cloudfunctions.net';

export type NotificationTargetType = 'all' | 'group' | 'member';
export type NotificationStatus = 'pending' | 'sent' | 'cancelled' | 'failed';

export interface AdminNotification {
  id: string;
  title: string;
  body: string;
  targetType: NotificationTargetType;
  targetId?: string;
  targetName?: string;
  deepLinkUrl?: string;
  status: NotificationStatus;
  scheduledAt?: string;
  sentAt?: string;
  sentCount?: number;
  failedCount?: number;
  createdBy: string;
  createdAt: string;
}

export interface SendNotificationRequest {
  title: string;
  body: string;
  targetType: NotificationTargetType;
  targetId?: string;
  deepLinkUrl?: string;
}

export interface ScheduleNotificationRequest extends SendNotificationRequest {
  scheduledAt: string;
}

export interface SendNotificationResponse {
  notificationId: string;
  targetCount: number;
  sentCount: number;
  failedCount: number;
}

export interface ScheduleNotificationResponse {
  notificationId: string;
  scheduledAt: string;
  targetType: string;
  targetName?: string;
}

export interface GetNotificationsResponse {
  notifications: AdminNotification[];
  hasMore: boolean;
}

async function getAuthToken(): Promise<string> {
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) {
    throw new Error('Not authenticated');
  }
  return user.getIdToken();
}

export const pushNotificationService = {
  /**
   * Send immediate notification
   */
  async sendNotification(request: SendNotificationRequest): Promise<SendNotificationResponse> {
    const token = await getAuthToken();

    const response = await fetch(`${API_BASE_URL}/sendAdminNotification`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    });

    const data = await response.json();

    if (!response.ok || !data.success) {
      throw new Error(data.error || 'Failed to send notification');
    }

    return data.data;
  },

  /**
   * Schedule notification for future delivery
   */
  async scheduleNotification(request: ScheduleNotificationRequest): Promise<ScheduleNotificationResponse> {
    const token = await getAuthToken();

    const response = await fetch(`${API_BASE_URL}/scheduleAdminNotification`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    });

    const data = await response.json();

    if (!response.ok || !data.success) {
      throw new Error(data.error || 'Failed to schedule notification');
    }

    return data.data;
  },

  /**
   * Get notification history
   */
  async getNotifications(params?: {
    limit?: number;
    status?: NotificationStatus;
    lastNotificationId?: string;
  }): Promise<GetNotificationsResponse> {
    const token = await getAuthToken();

    const queryParams = new URLSearchParams();
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.status) queryParams.append('status', params.status);
    if (params?.lastNotificationId) queryParams.append('lastNotificationId', params.lastNotificationId);

    const response = await fetch(
      `${API_BASE_URL}/getAdminNotifications?${queryParams.toString()}`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      }
    );

    const data = await response.json();

    if (!response.ok || !data.success) {
      throw new Error(data.error || 'Failed to get notifications');
    }

    return data.data;
  },

  /**
   * Cancel scheduled notification
   */
  async cancelNotification(notificationId: string): Promise<void> {
    const token = await getAuthToken();

    const response = await fetch(`${API_BASE_URL}/cancelScheduledNotification`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ notificationId }),
    });

    const data = await response.json();

    if (!response.ok || !data.success) {
      throw new Error(data.error || 'Failed to cancel notification');
    }
  },
};
