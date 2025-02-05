// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { DateKeys } from 'core-app/shared/components/datepicker/datepicker.modal';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { DateOption } from 'flatpickr/dist/types/options';

@Injectable({ providedIn: 'root' })
export class DatePickerModalHelper {
  currentlyActivatedDateField:DateKeys;

  /**
   * Map the date to the internal format,
   * setting to null if it's empty.
   * @param date
   */
  // eslint-disable-next-line class-methods-use-this
  mappedDate(date:string):string|null {
    return date === '' ? null : date;
  }

  // eslint-disable-next-line class-methods-use-this
  parseDate(date:Date|string):Date|'' {
    if (date instanceof Date) {
      return new Date(date.setHours(0, 0, 0, 0));
    } if (date === '') {
      return '';
    }
    return new Date(new Date(date).setHours(0, 0, 0, 0));
  }

  // eslint-disable-next-line class-methods-use-this
  validDate(date:Date|string):boolean {
    return (date instanceof Date)
      || (date === '')
      || !!new Date(date).valueOf();
  }

  areDatesEqual(firstDate:Date|string, secondDate:Date|string):boolean {
    const parsedDate1 = this.parseDate(firstDate);
    const parsedDate2 = this.parseDate(secondDate);

    if ((typeof (parsedDate1) === 'string') || (typeof (parsedDate2) === 'string')) {
      return false;
    }
    return parsedDate1.getTime() === parsedDate2.getTime();
  }

  setCurrentActivatedField(val:DateKeys):void {
    this.currentlyActivatedDateField = val;
  }

  toggleCurrentActivatedField():void {
    this.currentlyActivatedDateField = this.currentlyActivatedDateField === 'start' ? 'end' : 'start';
  }

  isStateOfCurrentActivatedField(val:DateKeys):boolean {
    return this.currentlyActivatedDateField === val;
  }

  // eslint-disable-next-line class-methods-use-this
  setDates(dates:DateOption|DateOption[], datePicker:DatePicker, enforceDate?:Date):void {
    const { currentMonth } = datePicker.datepickerInstance;
    const { currentYear } = datePicker.datepickerInstance;
    datePicker.setDates(dates);

    if (enforceDate) {
      datePicker.datepickerInstance.currentMonth = enforceDate.getMonth();
      datePicker.datepickerInstance.currentYear = enforceDate.getFullYear();
    } else {
      // Keep currently active month and avoid jump because of two-month layout
      datePicker.datepickerInstance.currentMonth = currentMonth;
      datePicker.datepickerInstance.currentYear = currentYear;
    }

    datePicker.datepickerInstance.redraw();
  }
}
